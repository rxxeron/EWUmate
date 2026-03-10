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

        // 2. Determine All Active Semesters
        const { data: activeSems, error: activeSemError } = await supabase
            .from('active_semester')
            .select('current_semester_code, current_semester')
            .eq('is_active', true)

        if (activeSemError) throw activeSemError
        if (!activeSems || activeSems.length === 0) {
            return new Response(JSON.stringify({ error: 'No active semesters found' }), {
                status: 400,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            })
        }

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
                // The 'semester' field will be re-mapped for each specific semester during insertion
                semester: ''
            });

            // Increment day
            currentDate.setDate(currentDate.getDate() + 1);
        }

        // 4. Insert Holidays (Bulk) into ALL active calendars
        let totalInserted = 0;
        for (const sem of activeSems) {
            const table = `calendar_${sem.current_semester_code.toLowerCase()}`;
            const pretty = sem.current_semester || sem.current_semester_code;

            // Re-map with current pretty semester name
            const semanticDates = datesToInsert.map(d => ({ ...d, semester: pretty }));

            const { error: insertError } = await supabase
                .from(table)
                .insert(semanticDates);

            if (!insertError) totalInserted += semanticDates.length;
            else console.error(`Failed to insert into ${table}:`, insertError);
        }

        return new Response(JSON.stringify({
            success: true,
            message: `Added holidays to ${activeSems.length} active calendars (${totalInserted} total rows)`
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
