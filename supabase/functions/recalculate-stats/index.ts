import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const GRADE_POINTS: Record<string, number> = {
    "A+": 4.00, "A": 3.75, "A-": 3.50,
    "B+": 3.25, "B": 3.00, "B-": 2.75,
    "C+": 2.50, "C": 2.25, "D": 2.00, "F": 0.00,
};

function semSortKey(semStr: string): number {
    const match = semStr.match(/(Spring|Summer|Fall)\s*(\d{4})/i);
    if (!match) return 0;
    const term = match[1].toLowerCase();
    const year = parseInt(match[2]);
    const termOrder: Record<string, number> = { "spring": 1, "summer": 2, "fall": 3 };
    return year * 10 + (termOrder[term] || 0);
}

function getRequiredTotal(programId: string, departments: any[]): number {
    const pId = (programId || "").toLowerCase().trim();
    if (!pId) return 140.0;

    for (const dept of departments) {
        const progs = dept.programs || [];
        for (const p of progs) {
            if (p.id?.toLowerCase() === pId) {
                return parseFloat(p.credits || "140.0");
            }
        }
    }

    // Fallback
    if (pId.includes("cse") || pId.includes("ice")) return 140.0;
    if (pId.includes("eee") || pId.includes("ete")) return 148.0;
    if (pId.includes("pharma") || pId.includes("pha")) return 160.0;
    if (pId.includes("bba") || pId.includes("mba")) return 123.0;
    return 140.0;
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
        const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
        const supabase = createClient(supabaseUrl, supabaseKey);

        const { user_id } = await req.json();
        if (!user_id) throw new Error("user_id is required");

        // 1. Fetch Academic Data
        const { data: acadData } = await supabase
            .from("academic_data")
            .select("*")
            .eq("user_id", user_id)
            .maybeSingle();

        const rawSemesters = acadData?.semesters;
        const rawHistory = acadData?.course_history;

        if (!rawSemesters && !rawHistory) {
            return new Response(JSON.stringify({ status: "no_data", message: "No course history found" }), { headers: corsHeaders });
        }

        // 2. Fetch Course Metadata
        const { data: metaData } = await supabase
            .from("course_metadata")
            .select("code, name, credits, credit_val");

        const creditMap: Record<string, number> = {};
        const nameMap: Record<string, string> = {};

        (metaData || []).forEach(row => {
            const code = (row.code || "").toUpperCase().replace(/\s+/g, "");
            nameMap[code] = row.name || code;

            let val = row.credit_val;
            if (val === null || val === undefined || val === "") {
                val = row.credits || "3";
            }

            const parsed = parseFloat(String(val).trim());
            creditMap[code] = (!isNaN(parsed) && parsed > 0) ? parsed : 3.0;
        });

        // 3. Normalize Semesters
        let normalized: { name: string, courses: [string, string][] }[] = [];

        // Count courses to decide source of truth
        const historyCount = rawHistory ? Object.values(rawHistory).reduce((acc: number, val: any) => acc + Object.keys(val || {}).length, 0) : 0;
        const semestersCount = Array.isArray(rawSemesters) ? rawSemesters.reduce((acc: number, val: any) => acc + (val.courses?.length || 0), 0) : 0;

        // If history has more data, use it. Otherwise use semesters.
        if (rawHistory && (historyCount >= semestersCount || !rawSemesters)) {
            const keys = Object.keys(rawHistory).sort((a, b) => semSortKey(a) - semSortKey(b));
            normalized = keys.map(name => {
                const coursesMap = rawHistory[name];
                const courses: [string, string][] = Object.entries(coursesMap).map(([c, g]) => [
                    c.toUpperCase().replace(/\s+/g, ""),
                    String(g || "")
                ]);
                return { name, courses };
            });
        } else if (Array.isArray(rawSemesters)) {
            normalized = rawSemesters.map((item: any) => {
                const name = item.semesterName || "";
                const courses: [string, string][] = (item.courses || []).map((c: any) => [
                    (c.code || c.courseCode || "").toUpperCase().replace(/\s+/g, ""),
                    c.grade || ""
                ]);
                return { name, courses };
            }).sort((a, b) => semSortKey(a.name) - semSortKey(b.name));
        }

        // 4. Calculate
        let cumPoints = 0.0;
        let cumCredits = 0.0;
        const semestersList = [];

        for (const sem of normalized) {
            let termPoints = 0.0;
            let termCredits = 0.0;
            const termCourses = [];

            for (const [code, grade] of sem.courses) {
                if (!grade) continue;

                const credits = creditMap[code] || 3.0;
                let gp = 0.0;

                if (["W", "I", "", "Ongoing"].includes(grade)) {
                    // No points
                } else {
                    gp = GRADE_POINTS[grade] || 0.0;
                    termPoints += gp * credits;
                    termCredits += credits;
                }

                termCourses.push({
                    code,
                    title: nameMap[code] || code,
                    credits,
                    grade,
                    point: gp
                });
            }

            const termGPA = termCredits > 0 ? termPoints / termCredits : 0.0;
            cumPoints += termPoints;
            cumCredits += termCredits;
            const cumGPA = cumCredits > 0 ? cumPoints / cumCredits : 0.0;

            semestersList.push({
                semesterName: sem.name,
                termGPA: Number(termGPA.toFixed(2)),
                cumulativeGPA: Number(cumGPA.toFixed(2)),
                courses: termCourses
            });
        }

        const cgpa = cumCredits > 0 ? cumPoints / cumCredits : 0.0;

        // 5. Credits Remained & Program Name
        const { data: profile } = await supabase.from("profiles").select("program_id").eq("id", user_id).maybeSingle();
        const { data: depts } = await supabase.from("departments").select("programs");

        let programName = "";
        const pId = (profile?.program_id || "").toLowerCase().trim();
        if (pId && depts) {
            for (const dept of depts) {
                for (const p of (dept.programs || [])) {
                    if (p.id?.toLowerCase() === pId) {
                        programName = p.name || "";
                        break;
                    }
                }
                if (programName) break;
            }
        }

        const totalRequired = getRequiredTotal(profile?.program_id, depts || []);
        const remained = Math.max(0.0, totalRequired - cumCredits);

        // 6. Update Database
        const payload = {
            user_id,
            semesters: semestersList,
            cgpa: Number(cgpa.toFixed(2)),
            total_credits_earned: Number(cumCredits.toFixed(1)),
            remained_credits: Number(remained.toFixed(1)),
            program_name: programName,
            last_updated: new Date().toISOString()
        };

        const { error: upsertError } = await supabase.from("academic_data").upsert(payload);
        if (upsertError) throw upsertError;

        return new Response(JSON.stringify({
            status: "ok",
            cgpa: Number(cgpa.toFixed(2)),
            total_credits: Number(cumCredits.toFixed(1)),
            remained_credits: Number(remained.toFixed(1)),
            semesters_count: semestersList.length
        }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });

    } catch (error) {
        console.error(error);
        return new Response(JSON.stringify({ error: error.message }), { headers: corsHeaders, status: 500 });
    }
});
