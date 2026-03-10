import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        let { semester, user_id } = await req.json()

        const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
        const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        const supabase = createClient(supabaseUrl, supabaseKey)

        if (!semester) {
            let semesterType = 'tri';
            if (user_id) {
                const { data: profile } = await supabase.from('profiles').select('department').eq('id', user_id).maybeSingle();
                const deptName = profile?.department || '';

                const { data: deptData } = await supabase
                    .from('departments')
                    .select('semester_type')
                    .eq('name', deptName)
                    .maybeSingle();

                semesterType = deptData?.semester_type || 'tri';
            }

            const { data: activeSemData, error: activeSemError } = await supabase
                .from('active_semester')
                .select('current_semester_code')
                .eq('semester_type', semesterType)
                .single()

            if (activeSemError || !activeSemData) {
                throw new Error("Missing semester code and failed to fetch active semester")
            }
            semester = activeSemData.current_semester_code
        }

        console.log(`Processing exams for semester: ${semester}, user: ${user_id || 'ALL'}`);

        // 1. Check if Exam Schedule table exists
        const { data: tableCheck, error: tableError } = await supabase
            .rpc('get_table_exists', { p_table_name: `exams_${semester.toLowerCase()}` })

        // If RPC doesn't exist or returns false, we might need a fallback check
        // For now, let's try to query and see if it fails with 404/42P01

        // 1.5 Fetch Course & Exam Lists
        let mainCourses: any[] = []
        let mainExams: any[] = []
        let standardCourses: any[] = []
        let standardExams: any[] = []

        // Fetch Main (Departmental if applicable)
        const { data: cData } = await supabase.from(`courses_${semester.toLowerCase()}`).select('doc_id, code, course_name, sessions')
        const { data: eData } = await supabase.from(`exams_${semester.toLowerCase()}`).select('*')
        mainCourses = cData || []
        mainExams = eData || []

        // If it's a departmental semester, fetch the standard trimester tables as well
        const isBi = semester.toLowerCase().endsWith('_phrm_llb')
        if (isBi) {
            const standardCode = semester.split('_')[0] // e.g. "Spring2026"
            const { data: scData } = await supabase.from(`courses_${standardCode.toLowerCase()}`).select('doc_id, code, course_name, sessions')
            const { data: seData } = await supabase.from(`exams_${standardCode.toLowerCase()}`).select('*')
            standardCourses = scData || []
            standardExams = seData || []
        }

        const allCourses = [...mainCourses, ...standardCourses]

        // Check if any exam data was fetched
        if ((!mainExams || mainExams.length === 0) && (!standardExams || standardExams.length === 0)) {
            console.log(`No exam tables found for semester: ${semester}`);
            return new Response(
                JSON.stringify({ status: 'skipped', message: "Exam schedule not uploaded yet or is empty." }),
                { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
            )
        }

        // 2. Fetch Profiles
        let query = supabase.from('profiles').select('id, enrolled_sections')
        if (user_id) {
            query = query.eq('id', user_id)
        }

        const { data: profiles, error: profileErr } = await query
        if (profileErr) throw new Error("Failed to fetch profiles")

        let updatedCount = 0

        // 3. Match Logic
        for (const profile of profiles) {
            if (!profile.enrolled_sections || profile.enrolled_sections.length === 0) {
                // Clear cache if no sections
                await supabase.from('profiles').update({ exam_dates_cache: {} }).eq('id', profile.id)
                updatedCount++
                continue
            }

            const newCache: Record<string, any> = {}

            for (const sectionId of profile.enrolled_sections) {
                // Find the full course object in the unified list
                const course = allCourses.find((c: any) => c.doc_id === sectionId)
                if (!course || !course.sessions) continue

                const code = (course.code || '').toUpperCase()
                const isDeptCourse = code.startsWith('PHRM') || code.startsWith('LAW')
                const targetExams = isDeptCourse ? mainExams : (isBi ? standardExams : mainExams)

                // Generate pattern
                const days = new Set<string>()
                for (const sess of course.sessions) {
                    const sessionType = (sess.type || sess.sessionType || '').toLowerCase()
                    if (sessionType.includes('lab') || sessionType.includes('tutorial')) {
                        continue // Skip labs and tutorials for exam matching
                    }

                    if (sess.day) {
                        const str = sess.day.trim()
                        if (str.length <= 4 && str.toUpperCase() === str) {
                            // Probably an abbreviation like "TR" or "STR"
                            for (const char of str) {
                                days.add(char)
                            }
                        } else {
                            days.add(str)
                        }
                    }
                }

                const codes: string[] = []
                for (const day of days) {
                    const d = day.toLowerCase().trim()
                    if (d === 'sunday' || d === 's') codes.push('S')
                    else if (d === 'monday' || d === 'm') codes.push('M')
                    else if (d === 'tuesday' || d === 't') codes.push('T')
                    else if (d === 'wednesday' || d === 'w') codes.push('W')
                    else if (d === 'thursday' || d === 'r') codes.push('R')
                    else if (d === 'friday' || d === 'f') codes.push('F')
                    else if (d === 'saturday' || d === 'a') codes.push('A')
                }

                const order: Record<string, number> = { 'S': 0, 'M': 1, 'T': 2, 'W': 3, 'R': 4, 'F': 5, 'A': 6 }
                codes.sort((a, b) => (order[a] ?? 99) - (order[b] ?? 99))
                const pattern = codes.join('')

                // Find Exam Match in the determined target list
                const match = targetExams.find((e: any) => e.class_days?.toUpperCase() === pattern.toUpperCase())
                if (match) {
                    const dayName = match.exam_day?.toLowerCase()?.trim() || ''
                    let dayChar = ''
                    if (dayName === 'sunday') dayChar = 'S'
                    else if (dayName === 'monday') dayChar = 'M'
                    else if (dayName === 'tuesday') dayChar = 'T'
                    else if (dayName === 'wednesday') dayChar = 'W'
                    else if (dayName === 'thursday') dayChar = 'R'
                    else if (dayName === 'friday') dayChar = 'F'
                    else if (dayName === 'saturday') dayChar = 'A'

                    let class_time = "Time TBA"
                    let class_venue = "Venue TBA"

                    if (dayChar) {
                        for (const sess of course.sessions) {
                            const sessionType = (sess.type || sess.sessionType || '').toLowerCase()
                            if (sessionType.includes('lab') || sessionType.includes('tutorial')) continue

                            if (sess.day && String(sess.day).includes(dayChar)) {
                                if (sess.startTime && sess.endTime) {
                                    class_time = `${sess.startTime} - ${sess.endTime}`
                                }
                                if (sess.room) {
                                    class_venue = sess.room
                                }
                                break
                            }
                        }
                    }

                    if (class_venue === "Venue TBA") {
                        for (const sess of course.sessions) {
                            const sessionType = (sess.type || sess.sessionType || '').toLowerCase()
                            if (sessionType.includes('lab') || sessionType.includes('tutorial')) continue

                            if (sess.startTime && sess.endTime && class_time === "Time TBA") {
                                class_time = `${sess.startTime} - ${sess.endTime}`
                            }
                            if (sess.room && class_venue === "Venue TBA") {
                                class_venue = sess.room
                            }
                            if (class_venue !== "Venue TBA" && class_time !== "Time TBA") break
                        }
                    }

                    newCache[course.code] = {
                        exam_date: match.exam_date,
                        exam_day: match.exam_day,
                        pattern: pattern,
                        class_time: class_time,
                        class_venue: class_venue
                    }
                }
            }

            // 4. Update Profile via bulk RPC
            await supabase.from('profiles').update({ exam_dates_cache: newCache }).eq('id', profile.id)
            updatedCount++

            // 5. Auto-generate Tasks
            // Delete existing incomplete 'finalExam' tasks for this user to avoid duplicates if schedule changes
            await supabase.from('tasks')
                .delete()
                .eq('user_id', profile.id)
                .eq('type', 'finalExam')
                .eq('is_completed', false)

            const tasksToInsert = []
            for (const courseCode of Object.keys(newCache)) {
                const cacheData = newCache[courseCode]
                const course = allCourses.find((c: any) => c.code === courseCode)

                let examDateTime = new Date(cacheData.exam_date + " 23:59:00") // default end of day

                if (cacheData.class_time && cacheData.class_time !== "Time TBA") {
                    const startTimeStr = cacheData.class_time.split(' - ')[0]
                    const tryDate = new Date(`${cacheData.exam_date} ${startTimeStr}`)
                    if (!isNaN(tryDate.getTime())) {
                        examDateTime = tryDate
                    }
                }

                if (isNaN(examDateTime.getTime())) {
                    examDateTime = new Date() // Fallback
                }

                tasksToInsert.push({
                    user_id: profile.id,
                    title: `Final Exam: ${courseCode}`,
                    course_code: courseCode,
                    course_name: course ? (course.course_name || course.courseName || courseCode) : courseCode,
                    assign_date: new Date().toISOString(),
                    due_date: examDateTime.toISOString(),
                    submission_type: 'offline',
                    type: 'finalExam',
                    is_completed: false
                })
            }

            if (tasksToInsert.length > 0) {
                const { error: taskError } = await supabase.from('tasks').insert(tasksToInsert)
                if (taskError) {
                    console.error(`Failed to insert tasks for profile ${profile.id}:`, taskError)
                }
            }
        }

        return new Response(
            JSON.stringify({
                status: 'ok',
                message: `Updated exam cache for ${updatedCount} profiles`,
                semester: semester
            }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
        )

    } catch (error: any) {
        return new Response(
            JSON.stringify({ error: error.message }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
        )
    }
})
