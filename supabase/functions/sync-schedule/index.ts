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
        const userId = payload.user_id || payload.record?.id || payload.record?.user_id;

        if (track) {
            return await handleBulkTrackSync(supabase, track);
        } else if (userId) {
            return await handleSingleUserSync(supabase, userId);
        } else {
            throw new Error("Missing user_id or track");
        }

    } catch (error: any) {
        console.error("Sync-Schedule Error:", error);
        return new Response(JSON.stringify({ success: false, error: error.message }), { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }, 
            status: 400 
        });
    }
});

async function handleSingleUserSync(supabase: any, userId: string) {
    // 1. Fetch Profile & Semester Config
    const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('track')
        .eq('id', userId)
        .single();

    if (profileError || !profile) throw new Error("Profile not found");

    const track = profile.track || 'tri_semester';
    const { data: config, error: configError } = await supabase
        .from('active_semester')
        .select('current_semester_code')
        .eq('track', track)
        .maybeSingle();

    const semesterCode = config?.current_semester_code;
    if (configError || !semesterCode) throw new Error("No active semester found");

    const cleanSem = semesterCode.replace(/\s+/g, '').replace(/_/g, '').toLowerCase();
    const courseTable = `courses_${cleanSem}`;

    // 2. Fetch Enrollments
    const { data: enrollments, error: enrollError } = await supabase
        .from('enrollments')
        .select('section_id')
        .eq('user_id', userId)
        .eq('semester_code', semesterCode);

    if (enrollError) throw enrollError;
    
    let weeklyTemplate = {};
    if (enrollments && enrollments.length > 0) {
        const sectionIds = enrollments.map((e: any) => e.section_id);
        const { data: courses, error: courseError } = await supabase
            .from(courseTable)
            .select('course_code, course_name, schedule_data')
            .in('id', sectionIds);

        if (courseError) throw courseError;
        weeklyTemplate = generateTemplate(courses);
    }

    // 3. Upsert
    const { error: upsertError } = await supabase
        .from('user_semester_states')
        .upsert({
            user_id: userId,
            semester_code: semesterCode,
            weekly_grid_cache: weeklyTemplate,
            updated_at: new Date().toISOString()
        }, { onConflict: 'user_id, semester_code' });

    if (upsertError) throw upsertError;
    return new Response(JSON.stringify({ success: true, message: "Sync complete" }), { headers: corsHeaders });
}

async function handleBulkTrackSync(supabase: any, track: string) {

    // 1. Get Active Semester
    const { data: config, error: configError } = await supabase
        .from('active_semester')
        .select('current_semester_code')
        .eq('track', track)
        .maybeSingle();

    const semesterCode = config?.current_semester_code;
    if (configError || !semesterCode) throw new Error("No active semester found for track");

    const cleanSem = semesterCode.replace(/\s+/g, '').replace(/_/g, '').toLowerCase();
    const courseTable = `courses_${cleanSem}`;

    // 2. Fetch all users in track
    const { data: users, error: userError } = await supabase
        .from('profiles')
        .select('id')
        .eq('track', track);

    if (userError) throw userError;
    if (!users || users.length === 0) return new Response(JSON.stringify({ success: true, message: "No users in track" }), { headers: corsHeaders });

    // 3. Fetch all enrollments for these users
    const userIds = users.map((u: any) => u.id);
    const { data: enrollments, error: enrollError } = await supabase
        .from('enrollments')
        .select('user_id, section_id')
        .in('user_id', userIds)
        .eq('semester_code', semesterCode);

    if (enrollError) throw enrollError;

    // 4. Fetch all relevant courses
    const sectionIds = [...new Set(enrollments.map((e: any) => e.section_id))];
    const { data: courses, error: courseError } = await supabase
        .from(courseTable)
        .select('id, course_code, course_name, schedule_data')
        .in('id', sectionIds);

    if (courseError) throw courseError;
    const courseMap = (courses || []).reduce((acc: any, c: any) => { acc[c.id] = c; return acc; }, {});

    // 5. Generate and batch upsert
    const upserts = users.map((u: any) => {
        const userSections = enrollments
            .filter((e: any) => e.user_id === u.id)
            .map((e: any) => courseMap[e.section_id])
            .filter(Boolean);

        const template = generateTemplate(userSections);
        return {
            user_id: u.id,
            semester_code: semesterCode,
            weekly_grid_cache: template,
            updated_at: new Date().toISOString()
        };
    });

    // Chunk upserts if count > 100
    const chunkSize = 50;
    for (let i = 0; i < upserts.length; i += chunkSize) {
        const chunk = upserts.slice(i, i + chunkSize);
        const { error } = await supabase
            .from('user_semester_states')
            .upsert(chunk, { onConflict: 'user_id, semester_code' });
        if (error) console.error("Bulk sync chunk error:", error);
    }

    return new Response(JSON.stringify({ success: true, count: upserts.length }), { headers: corsHeaders });
}

function generateTemplate(courses: any[]) {
    const dayMap: Record<number, string> = { 0: 'Sunday', 1: 'Monday', 2: 'Tuesday', 3: 'Wednesday', 4: 'Thursday', 5: 'Friday', 6: 'Saturday' };
    const ewuCodeMap: Record<string, string> = { 'Sunday': 'S', 'Monday': 'M', 'Tuesday': 'T', 'Wednesday': 'W', 'Thursday': 'R', 'Friday': 'F', 'Saturday': 'A' };
    const template: Record<string, any[]> = {};

    Object.values(dayMap).forEach(dayName => {
        const ewuDayCode = ewuCodeMap[dayName];
        const dailyClasses: any[] = [];

        courses.forEach((course: any) => {
            const sessions = course.schedule_data || [];
            sessions.forEach((sess: any) => {
                if ((sess.day || '').includes(ewuDayCode)) {
                    dailyClasses.push({
                        courseCode: course.course_code,
                        courseName: course.course_name,
                        startTime: sess.startTime || sess.start_time || 'TBA',
                        endTime: sess.endTime || sess.end_time || 'TBA',
                        room: sess.room || 'TBA',
                        type: sess.type || 'Theory',
                        faculty: sess.faculty || sess.faculty_initials || '',
                    });
                }
            });
        });
        template[dayName] = dailyClasses;
    });
    return template;
}
