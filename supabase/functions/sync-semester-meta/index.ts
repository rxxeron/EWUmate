import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        const payload = await req.json();
        const track = payload.track || payload.record?.track;
        const semesterCode = payload.record?.current_semester_code || payload.semester_code;

        if (!track) {
            // Cron Mode: Sync all tracks
            console.log("Sync-Semester-Meta: No track provided, syncing all tracks.");
            const { data: tracks, error: trackError } = await supabase.from('active_semester').select('track, current_semester_code');
            if (trackError) throw trackError;
            
            const results = [];
            for (const t of (tracks || [])) {
                results.push(await syncSemesterDates(supabase, t.track, t.current_semester_code));
            }
            return new Response(JSON.stringify({ success: true, count: results.length }), { 
                headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
            });
        }

        if (!semesterCode) {
            throw new Error("Missing semester_code for specific track sync");
        }

        return await syncSemesterDates(supabase, track, semesterCode);

    } catch (error: any) {
        console.error("Sync-Semester-Meta Error:", error);
        return new Response(JSON.stringify({ success: false, error: error.message }), { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }, 
            status: 400 
        });
    }
});

async function syncSemesterDates(supabase: any, track: string, semesterCode: string) {
    const today = new Date();
    
    // 1. Fetch meta from CURRENT calendar
    console.log(`Syncing meta for ${track} using current sem: ${semesterCode}`);
    let currentMeta = await fetchMetaFromCalendar(supabase, track, semesterCode);
    if (!currentMeta) {
        return new Response(JSON.stringify({ success: false, message: `Calendar for ${semesterCode} unavailable.` }), { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        });
    }

    let updates: any = { ...currentMeta };
    let switchPerformed = false;

    // 2. Check for Semester Switch threshold
    const switchDateStr = currentMeta.semester_switch_date;
    const switchDate = switchDateStr ? new Date(switchDateStr) : null;

    if (switchDate && today >= switchDate) {
        console.log(`Semester switch threshold reached (${switchDateStr}). Automating transition...`);
        const nextSem = calculateNextSemester(semesterCode, track);
        
        if (nextSem) {
            updates.current_semester_code = nextSem;
            updates.next_semester_code = calculateNextSemester(nextSem, track);
            switchPerformed = true;

            // 3. IMPORTANT: Try to fetch dates from the NEW calendar immediately to be accurate
            console.log(`Switching to ${nextSem}. Attempting to sync dates from new calendar...`);
            const newMeta = await fetchMetaFromCalendar(supabase, track, nextSem);
            if (newMeta) {
                // Merge new dates, preferring those in the new calendar if they exist
                updates = { ...updates, ...newMeta };
                // Ensure the codes we just calculated remain correct
                updates.current_semester_code = nextSem;
                updates.next_semester_code = calculateNextSemester(nextSem, track);
            }
        }
    }

    // 4. Update active_semester
    const { error: updateError } = await supabase
        .from('active_semester')
        .update(updates)
        .eq('track', track);

    if (updateError) throw updateError;

    // 5. Trigger side effects if switched
    if (switchPerformed) {
        console.log(`Switch finalized. Performing enrollment shift for ${updates.current_semester_code}...`);
        
        // Final Attempt: Direct update using the REST API with a more resilient strategy
        // We use an RPC or a loop if needed, but here we'll try to just catch the error 
        // and acknowledge that some rows might be blocked by retake constraints.
        const { data: shifted, error: shiftError } = await supabase
            .from('enrollments')
            .update({ status: 'enrolled' })
            .eq('semester_code', updates.current_semester_code)
            .eq('status', 'upcoming')
            .select();

        if (shiftError) {
            if (shiftError.code === '23505') {
                console.warn("Bulk shift hit unique constraint conflicts (retakes). Performing row-by-row shift.");
                const { data: records } = await supabase
                    .from('enrollments')
                    .select('id')
                    .eq('semester_code', updates.current_semester_code)
                    .eq('status', 'upcoming');
                
                if (records) {
                    for (const r of records) {
                        // Attempt each row individually. If one fails (due to retake), the others still succeed.
                        await supabase.from('enrollments').update({ status: 'enrolled' }).eq('id', r.id);
                    }
                }
                console.log("Row-by-row shift completed.");
            } else {
                console.error("Enrollment shift failed:", shiftError);
            }
        } else {
            console.log(`Successfully shifted ${shifted?.length || 0} enrollments to 'enrolled'.`);
        }

        try {
            await supabase.functions.invoke('sync-schedule', { body: { track: track } });
            console.log(`Bulk schedule sync triggered for track: ${track}`);
        } catch (e) {
            console.error("Bulk schedule sync trigger failed:", e);
        }
    }

    return new Response(JSON.stringify({ 
        success: true, 
        updated_to: updates.current_semester_code || semesterCode,
        switch_performed: switchPerformed 
    }), { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    });
}

async function fetchMetaFromCalendar(supabase: any, track: string, semesterCode: string) {
    const cleanSem = semesterCode.replace(/\s+/g, '').replace(/_/g, '').toLowerCase();
    const table = track === 'bi_semester' ? `calendar_${cleanSem}_phrm_llb` : `calendar_${cleanSem}`;
    
    const { data: events } = await supabase
        .from(table)
        .select('title, event_date')
        .order('event_date', { ascending: true });

    if (!events || events.length === 0) return null;

    const find = (keys: string[]) => events.find((e: any) => keys.some(k => e.title.includes(k)))?.event_date;
    const findLast = (keys: string[]) => {
        const m = events.filter((e: any) => keys.some(k => e.title.includes(k)));
        return m.length > 0 ? m[m.length - 1].event_date : null;
    };

    return {
        classes_start_date: find(["Classes Begin", "First Day of Classes"]),
        classes_end_date: find(["Last Day of Classes"]),
        final_exam_start: find(["Final Examination Begin", "Final Exam Begin", "Final Examination"]),
        final_exam_end: findLast(["Final Examination", "Final Exam"]),
        advising_start_date: find(["Online Advising", "Advising of Courses"]),
        advising_end_date: findLast(["Online Advising", "Advising of Courses"]),
        grade_submission_start: find(["Grade Submission", "Submission of Final Grade"]),
        grade_submission_deadline: findLast(["Grade Submission", "Submission of Final Grade"]),
        semester_switch_date: findLast(["University Reopens"])
    };
}

function calculateNextSemester(current: string, track: string) {
    const yearMatch = current.match(/\d{4}/);
    let year = yearMatch ? parseInt(yearMatch[0]) : new Date().getFullYear();
    const low = current.toLowerCase();

    if (track === 'bi_semester') {
        return low.includes('spring') ? `Fall${year}` : `Spring${year + 1}`;
    } else {
        if (low.includes('spring')) return `Summer${year}`;
        if (low.includes('summer')) return `Fall${year}`;
        if (low.includes('fall')) return `Spring${year + 1}`;
        return `Spring${year + 1}`;
    }
}
