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

        const { name, startDate, endDate, secret } = await req.json()

        // 1. Verify Secret
        const adminPassword = Deno.env.get('ADMIN_PASSWORD')
        if (secret !== adminPassword) {
            return new Response(JSON.stringify({ error: 'Unauthorized' }), {
                status: 401,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            })
        }

        if (!name || !startDate) {
            return new Response(JSON.stringify({ error: 'Name and Start Date are required' }), {
                status: 400,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            })
        }

        // 2. Determine Active Semester
        const { data: activeSemData, error: activeSemError } = await supabase
            .from('active_semester')
            .select('current_semester_code, current_semester')
            .eq('is_active', true)
            .maybeSingle()

        if (activeSemError) throw activeSemError
        if (!activeSemData || !activeSemData.current_semester_code) {
            return new Response(JSON.stringify({ error: 'No active semester found' }), {
                status: 400,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            })
        }

        const semesterCode = activeSemData.current_semester_code
        const prettySemester = activeSemData.current_semester || semesterCode
        // Table name format: calendar_spring2026
        const tableName = `calendar_${semesterCode.toLowerCase()}`

        // 3. Prepare inserts for Date Range
        const start = new Date(startDate);
        const end = endDate ? new Date(endDate) : new Date(startDate);
        const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        const dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

        if (end < start) {
            return new Response(JSON.stringify({ error: 'End Date cannot be before Start Date' }), {
                status: 400,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        const datesToInsert = [];
        let currentDate = new Date(start);

        while (currentDate <= end) {
            const dayOfWeek = dayNames[currentDate.getDay()];

            // YYYY-MM-DD
            const isoDateString = currentDate.toISOString().split('T')[0];

            datesToInsert.push({
                date: isoDateString,
                day: dayOfWeek,
                name: name,
                type: 'Holiday',
                semester: prettySemester
            });

            // Increment day
            currentDate.setDate(currentDate.getDate() + 1);
        }

        // 4. Insert Holidays (Bulk)
        const { error: insertError } = await supabase
            .from(tableName)
            .insert(datesToInsert);

        if (insertError) throw insertError

        return new Response(JSON.stringify({
            success: true,
            semester: semesterCode,
            message: `Added ${datesToInsert.length} holiday(s) successfully`
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
