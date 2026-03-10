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
        const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
        const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
        const supabase = createClient(supabaseUrl, supabaseKey);

        const { semester } = await req.json();
        if (!semester) throw new Error("semester code is required");

        const cleanSem = semester.toLowerCase().replace(/\s+/g, '');
        const advisingTable = `advising_${cleanSem}`;

        console.log(`Matching advising slots for semester: ${cleanSem}`);

        // 1. Fetch Advising Slots
        const { data: slots, error: slotsErr } = await supabase
            .from(advisingTable)
            .select("*");

        if (slotsErr || !slots) throw new Error(`Failed to fetch slots: ${slotsErr?.message}`);

        // 2. Fetch Profiles with Academic Data
        const { data: profiles, error: profErr } = await supabase
            .from("profiles")
            .select(`
                id,
                department,
                academic_data (
                    total_credits_earned
                )
            `);

        if (profErr || !profiles) throw new Error(`Failed to fetch profiles: ${profErr?.message}`);

        console.log(`Processing ${profiles.length} profiles...`);

        let updatedCount = 0;

        for (const profile of profiles) {
            const userId = profile.id;
            const dept = (profile.department || "").toUpperCase();
            const acadData = Array.isArray(profile.academic_data) ? profile.academic_data[0] : profile.academic_data;
            const credits = acadData?.total_credits_earned || 0;

            // Find matching slot
            // Rules:
            // 1. Credits must be between min and max
            // 2. If allowed_departments is not empty, student's dept must be in it
            const match = slots.find(s => {
                const creditMatch = credits >= (s.min_credits || 0) && credits <= (s.max_credits || 999);
                if (!creditMatch) return false;

                const allowedDepts = s.allowed_departments || [];
                if (allowedDepts.length === 0) return true; // Open to all if empty

                return allowedDepts.some((d: string) => d.toUpperCase() === dept || (dept === "PHARMACY" && (d === "PHR" || d === "B.PHARM")));
            });

            if (match) {
                const displaySlot = `${match.date} | ${match.start_time} - ${match.end_time}`;

                await supabase
                    .from("profiles")
                    .update({ advising_slot: displaySlot })
                    .eq("id", userId);

                updatedCount++;
            }
        }

        return new Response(JSON.stringify({
            status: "ok",
            updated_count: updatedCount,
            total_profiles: profiles.length
        }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });

    } catch (error) {
        console.error(error);
        return new Response(JSON.stringify({ error: error.message }), { headers: corsHeaders, status: 500 });
    }
});
