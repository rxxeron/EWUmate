import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
    // Handle CORS
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        // Parse the payload from the Postgres webhook
        const payload = await req.json();
        console.log("Received webhook payload:", JSON.stringify(payload));

        // Expected shape from pg_net trigger:
        // { type: 'UPDATE', table: 'profiles', record: { id, enrolled_sections, ... }, old_record: { ... } }
        let record;
        if (payload.record) {
            record = payload.record;
        } else {
            // Direct invocation fallback testing
            record = payload;
        }

        const userId = record.id || record.user_id;
        const enrolledSections = record.enrolled_sections || [];

        if (!userId) {
            throw new Error("Missing user ID in payload");
        }

        console.log(`Processing schedule sync for user ${userId} with ${enrolledSections.length} sections`);

        // 1. Determine active semester cycle via department mapping
        const deptName = record.department || '';

        const { data: deptData } = await supabase
            .from('departments')
            .select('semester_type')
            .eq('name', deptName)
            .maybeSingle();

        const semesterType = deptData?.semester_type || 'tri';

        const { data: configData, error: configError } = await supabase
            .from('active_semester')
            .select('current_semester_code')
            .eq('semester_type', semesterType)
            .single();

        if (configError) throw new Error(`Failed to fetch active semester: ${configError.message}`);

        const activeSemester = configData?.current_semester_code;
        if (!activeSemester) {
            console.log("No active semester found. Exiting.");
            return new Response(JSON.stringify({ message: "No active semester" }), { headers: corsHeaders, status: 200 });
        }

        const cleanSemester = activeSemester.replace(/\s+/g, '');
        const courseTableName = `courses_${cleanSemester.toLowerCase()}`;

        // 2. Clear schedule if no sections
        if (!enrolledSections || enrolledSections.length === 0) {
            console.log(`Clearing schedule for user ${userId}, semester ${cleanSemester}`);
            const { error: clearError } = await supabase
                .from('user_schedules')
                .upsert({
                    user_id: userId,
                    semester: cleanSemester,
                    weekly_template: {},
                    last_updated: new Date().toISOString()
                }, { onConflict: 'user_id, semester' });

            if (clearError) throw clearError;
            return new Response(JSON.stringify({ message: "Schedule cleared" }), { headers: corsHeaders, status: 200 });
        }

        // 3. Fetch full Course details
        const isBi = cleanSemester.toLowerCase().endsWith('_phrm_llb');
        let combinedCourses: any[] = [];
        let remainingIds = [...enrolledSections];

        // 3.1 Try Specialized Table first
        const { data: mainCourses } = await supabase
            .from(courseTableName)
            .select('*')
            .in('doc_id', enrolledSections);

        if (mainCourses) {
            combinedCourses = [...mainCourses];
            const foundIds = mainCourses.map(c => c.doc_id);
            remainingIds = remainingIds.filter(id => !foundIds.includes(id));
        }

        // 3.2 Try Standard Table for missing IDs (if user is bi-semester)
        if (isBi && remainingIds.length > 0) {
            const standardCode = cleanSemester.split('_')[0];
            const standardTable = `courses_${standardCode.toLowerCase()}`;
            console.log(`Checking standard table ${standardTable} for remaining ${remainingIds.length} sections`);

            const { data: stdCourses } = await supabase
                .from(standardTable)
                .select('*')
                .in('doc_id', remainingIds);

            if (stdCourses) {
                combinedCourses = [...combinedCourses, ...stdCourses];
                const foundIds = stdCourses.map(c => c.doc_id);
                remainingIds = remainingIds.filter(id => !foundIds.includes(id));
            }
        }

        // 3.3 Metadata Fallback
        if (remainingIds.length > 0) {
            console.log(`Still missing ${remainingIds.length} sections, trying metadata fallback`);
            const { data: fallbackCourses } = await supabase
                .from('course_metadata')
                .select('*')
                .in('id', remainingIds);

            if (fallbackCourses) {
                combinedCourses = [...combinedCourses, ...fallbackCourses];
            }
        }

        const courses = combinedCourses;

        if (!courses || courses.length === 0) {
            console.log("No matching courses found for the enrolled sections.");
            return new Response(JSON.stringify({ message: "No matching courses" }), { headers: corsHeaders, status: 200 });
        }

        // 4. Generate Weekly Template
        const template = {};
        const dayMap = {
            'S': 'Sunday',
            'M': 'Monday',
            'T': 'Tuesday',
            'W': 'Wednesday',
            'R': 'Thursday',
            'F': 'Friday',
            'A': 'Saturday',
        };

        for (const course of courses) {
            // Map properties, handling metadata fallback schema differences
            const courseCode = course.code;
            const courseName = course.course_name || course.name;
            const sessions = course.sessions || []; // Handle case if fallback has no sessions

            for (const session of sessions) {
                if (!session.day) continue;

                const chars = session.day.replace(/\s+/g, '').split('');
                for (const c of chars) {
                    const dayName = dayMap[c];
                    if (dayName) {
                        if (!template[dayName]) template[dayName] = [];
                        template[dayName].push({
                            courseCode: courseCode,
                            courseName: courseName,
                            type: session.type || 'Theory',
                            startTime: session.startTime || '',
                            endTime: session.endTime || '',
                            room: session.room || 'TBA',
                            faculty: session.faculty || '',
                        });
                    }
                }
            }
        }

        // 5. Fetch Holidays
        const { data: holidaysData, error: holidaysError } = await supabase
            .from('calendar')
            .select('date, name')
            .eq('semester', cleanSemester)
            .eq('type', 'Holiday');

        // Parse holidays to match ScheduleService behavior
        // Just passing along as is for now, client logic handles parsing
        const holidaysList = (holidaysData || []).map(h => ({
            date: h.date,
            name: h.name
        }));

        // 6. Upsert User Schedule
        const { error: upsertError } = await supabase
            .from('user_schedules')
            .upsert({
                user_id: userId,
                semester: cleanSemester,
                weekly_template: template,
                holidays: holidaysList,
                last_updated: new Date().toISOString()
            }, { onConflict: 'user_id, semester' });

        if (upsertError) throw upsertError;

        console.log(`Successfully synced schedule for ${userId}, semester ${cleanSemester}`);

        // 7. Auto-trigger match-exams for this user
        try {
            console.log(`Auto-triggering exam match for ${userId}`);
            const edge_func_url = `${supabaseUrl}/functions/v1/match-exams`;
            await fetch(edge_func_url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${supabaseServiceKey}`
                },
                body: JSON.stringify({
                    semester: cleanSemester,
                    user_id: userId
                })
            });
        } catch (e) {
            console.error("Failed to auto-trigger match-exams:", e);
            // Don't fail the whole request if this optional step fails
        }

        return new Response(JSON.stringify({
            message: "Successfully synced schedule and triggered exam match",
            userId: userId,
            semester: cleanSemester
        }), { headers: corsHeaders, status: 200 });

    } catch (error) {
        console.error("Error syncing schedule:", error);
        return new Response(JSON.stringify({ error: error.message }), { headers: corsHeaders, status: 500 });
    }
});
