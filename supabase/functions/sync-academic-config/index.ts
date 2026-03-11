import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const supabase = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        const { secret } = await req.json()

        // 1. Verify Secret
        const adminPassword = Deno.env.get('ADMIN_PASSWORD')
        if (secret !== adminPassword) {
            return new Response(JSON.stringify({ error: 'Unauthorized' }), {
                status: 401,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            })
        }

        // 2. Fetch all active semester configurations
        const { data: configs, error: configError } = await supabase
            .from('active_semester')
            .select('*')
            .eq('is_active', true)

        if (configError) throw configError
        if (!configs || configs.length === 0) {
            return new Response(JSON.stringify({ error: 'No active semesters found to sync' }), {
                status: 400,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            })
        }

        const keywordMap = {
            current_semester_start_date: ["First Day of Classes", "Classes Begin", "Semester Begins"],
            advising_start_date: ["Online Advising of Courses", "Online Advising", "Advising of Courses"],
            grade_submission_start: ["Final Examinations", "Final Exam", "Final Exams Begin"],
            grade_submission_deadline: ["Submission of Final Grades", "Final Grades Submission", "Grade Submission"]
        }

        const results = []

        // 3. Process each cycle
        for (const config of configs) {
            const semCode = config.current_semester_code.toLowerCase().replace(/\s/g, '')
            let tableName = `calendar_${semCode}`
            if (config.semester_type === 'bi') {
                tableName = `${tableName}_phrm_llb`
            }

            console.log(`Processing sync for ${config.semester_type} using ${tableName}`)

            // Fetch calendar data
            const { data: calendarRows, error: calendarError } = await supabase
                .from(tableName)
                .select('*')

            if (calendarError) {
                console.error(`Error fetching calendar ${tableName}:`, calendarError)
                results.push({ cycle: config.semester_type, status: 'error', error: 'Calendar table not found' })
                continue
            }

            const updates: any = {}

            // Match keywords to dates
            for (const [field, keywords] of Object.entries(keywordMap)) {
                const match = calendarRows.find(row => {
                    const title = (row.name || row.event || row.title || '').toLowerCase()
                    return keywords.some(kw => title.includes(kw.toLowerCase()))
                })

                if (match) {
                    const dateVal = match.date || match.date_string
                    if (dateVal) {
                        updates[field] = dateVal
                    }
                }
            }

            if (Object.keys(updates).length > 0) {
                const { error: updateError } = await supabase
                    .from('active_semester')
                    .update(updates)
                    .eq('id', config.id)

                if (updateError) {
                    results.push({ cycle: config.semester_type, status: 'error', error: updateError.message })
                } else {
                    results.push({ cycle: config.semester_type, status: 'success', fieldsUpdated: Object.keys(updates) })
                }
            } else {
                results.push({ cycle: config.semester_type, status: 'no_matches' })
            }
        }

        return new Response(JSON.stringify({
            success: true,
            message: 'Academic configuration sync completed',
            results: results
        }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })

    } catch (err: any) {
        return new Response(JSON.stringify({ error: err.message }), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
    }
})
