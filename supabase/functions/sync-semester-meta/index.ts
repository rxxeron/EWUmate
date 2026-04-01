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
    // 1. Resolve Calendar Table Name
    const cleanSem = semesterCode.replace(/\s+/g, '').replace(/_/g, '').toLowerCase();
    const calendarTable = track === 'bi_semester' ? `calendar_${cleanSem}_phrm_llb` : `calendar_${cleanSem}`;


    // 2. Fetch all events from that calendar
    const { data: events, error: fetchError } = await supabase
        .from(calendarTable)
        .select('title, event_date')
        .order('event_date', { ascending: true });

    if (fetchError) {
        // Table might not exist yet if PDF hasn't been uploaded
        console.warn(`Calendar table ${calendarTable} not found or error fetching.`);
        return new Response(JSON.stringify({ success: false, message: `Calendar table ${calendarTable} unavailable.` }), { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        });
    }

    if (!events || events.length === 0) {
        return new Response(JSON.stringify({ success: true, message: "Calendar table empty, skipping sync." }), { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        });
    }

    // 3. Mapping Logic
    const updates: any = {};
    
    const findDate = (keywords: string[]) => {
        const found = events.find((e: any) => keywords.some(k => e.title.includes(k)));
        return found?.event_date;
    };

    const findLastDate = (keywords: string[]) => {
        const matches = events.filter((e: any) => keywords.some(k => e.title.includes(k)));
        return matches.length > 0 ? matches[matches.length - 1].event_date : null;
    };

    updates.classes_start_date = findDate(["Classes Begin", "First Day of Classes"]);
    updates.classes_end_date = findDate(["Last Day of Classes"]);
    updates.final_exam_start = findDate(["Final Examination Begin", "Final Exam Begin", "Final Examination"]);
    updates.final_exam_end = findLastDate(["Final Examination", "Final Exam"]);
    updates.advising_start_date = findDate(["Online Advising", "Advising of Courses"]);
    updates.advising_end_date = findLastDate(["Online Advising", "Advising of Courses"]);
    updates.grade_submission_deadline = findLastDate(["Grade Submission", "Submission of Final Grade"]);
    updates.semester_switch_date = findLastDate(["University Reopens"]);

    // Clean up nulls
    Object.keys(updates).forEach(key => updates[key] === null && delete updates[key]);

    if (Object.keys(updates).length === 0) {
        return new Response(JSON.stringify({ success: true, message: "No matching dates found in calendar." }), { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        });
    }

    // 4. Determine if we should perform an automated switch
    const today = new Date();
    const switchDate = updates.semester_switch_date ? new Date(updates.semester_switch_date) : null;
    let switchPerformed = false;
    let nextSemesterToSet = null;

    if (switchDate && today >= switchDate) {
        
        // Logical Progression based on Track
        const current = semesterCode;
        const lowCurrent = current.toLowerCase();
        const yearMatch = current.match(/\d{4}/);
        let year = yearMatch ? parseInt(yearMatch[0]) : today.getFullYear();
        
        if (track === 'bi_semester') {
            // Bi-Semester: Spring -> Fall -> Spring (Next Year)
            if (lowCurrent.includes('spring')) {
                nextSemesterToSet = `Fall${year}`;
            } else if (lowCurrent.includes('fall')) {
                nextSemesterToSet = `Spring${year + 1}`;
            }
        } else {
            // Tri-Semester: Spring -> Summer -> Fall -> Spring (Next Year)
            if (lowCurrent.includes('spring')) {
                nextSemesterToSet = `Summer${year}`;
            } else if (lowCurrent.includes('summer')) {
                nextSemesterToSet = `Fall${year}`;
            } else if (lowCurrent.includes('fall')) {
                nextSemesterToSet = `Spring${year + 1}`;
            }
        }

        if (nextSemesterToSet) {
            updates.current_semester_code = nextSemesterToSet;
            
            // Calculate Next (the one after the new current) for the UI
            let futureSem = '';
            if (track === 'bi_semester') {
                if (nextSemesterToSet.includes('Spring')) futureSem = `Fall${year}`;
                else futureSem = `Spring${year + 1}`;
            } else {
                if (nextSemesterToSet.includes('Summer')) futureSem = `Fall${year}`;
                else if (nextSemesterToSet.includes('Fall')) futureSem = `Spring${year + 1}`;
                else futureSem = `Summer${year + 1}`;
            }
            
            updates.next_semester_code = futureSem;
            switchPerformed = true;
        }
    }

    // Update active_semester
    const { error: updateError } = await supabase
        .from('active_semester')
        .update(updates)
        .eq('track', track);

    if (updateError) throw updateError;

    // 5. Automated Semester Switch for Enrollments
    // Use 'ongoing' status as preferred by user
    const targetSem = switchPerformed ? updates.current_semester_code : updates.next_semester_code;
    
    // Track-Safe Update using RPC
    const { error: enrollUpdateError } = await supabase.rpc('shift_enrollments_by_track', {
        p_track: track,
        p_semester_code: targetSem,
        p_new_status: 'ongoing'
    });

    if (enrollUpdateError) {
        console.warn("Enrollment switch error (non-critical):", enrollUpdateError);
    }

    // 6. Global Schedule Orchestration
    try {
        await supabase.functions.invoke('sync-schedule', {
            body: { track: track }
        });
    } catch (e) {
        console.error("Bulk schedule sync trigger failed:", e);
    }

    return new Response(JSON.stringify({ 
        success: true, 
        updated: updates,
        switch_performed: switchPerformed,
        enrollments_switched: !enrollUpdateError,
    }), { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    });
}
