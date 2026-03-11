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
        for (const p of (dept.programs || [])) {
            if (p.id?.toLowerCase() === pId) {
                return parseFloat(p.credits || "140.0");
            }
        }
    }
    return 140.0;
}

async function repairAcademicData(supabase: any, user_id: string, creditMap: any, nameMap: any, departments: any[], profilesMap: any) {
    const { data: acadData } = await supabase.from("academic_data").select("*").eq("user_id", user_id).maybeSingle();
    if (!acadData) return { status: "skipped", message: "No academic record" };
    const rawSemesters = acadData.semesters;
    const rawHistory = acadData.course_history;
    if (!rawSemesters && !rawHistory) return { status: "skipped", message: "No history data" };

    let normalized: { name: string, courses: [string, string][] }[] = [];
    const historyCount = rawHistory ? Object.values(rawHistory).reduce((acc: number, val: any) => acc + Object.keys(val || {}).length, 0) : 0;
    const semestersCount = Array.isArray(rawSemesters) ? rawSemesters.reduce((acc: number, val: any) => acc + (val.courses?.length || 0), 0) : 0;

    if (rawHistory && (historyCount >= semestersCount || !rawSemesters)) {
        const keys = Object.keys(rawHistory).sort((a, b) => semSortKey(a) - semSortKey(b));
        normalized = keys.map(name => ({
            name,
            courses: Object.entries(rawHistory[name]).map(([c, g]) => [c.toUpperCase().replace(/\s+/g, ""), String(g || "")])
        }));
    } else if (Array.isArray(rawSemesters)) {
        normalized = rawSemesters.map((item: any) => ({
            name: item.semesterName || "",
            courses: (item.courses || []).map((c: any) => [(c.code || c.courseCode || "").toUpperCase().replace(/\s+/g, ""), c.grade || ""])
        })).sort((a, b) => semSortKey(a.name) - semSortKey(b.name));
    }

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
            if (!["W", "I", "Ongoing"].includes(grade)) {
                gp = GRADE_POINTS[grade] || 0.0;
                termPoints += gp * credits;
                termCredits += credits;
            }
            termCourses.push({ code, title: nameMap[code] || code, credits, grade, point: gp });
        }
        const termGPA = termCredits > 0 ? termPoints / termCredits : 0.0;
        cumPoints += termPoints;
        cumCredits += termCredits;
        const cumGPA = cumCredits > 0 ? cumPoints / cumCredits : 0.0;
        semestersList.push({ semesterName: sem.name, termGPA: Number(termGPA.toFixed(2)), cumulativeGPA: Number(cumGPA.toFixed(2)), courses: termCourses });
    }

    const cgpa = cumCredits > 0 ? cumPoints / cumCredits : 0.0;
    const programId = profilesMap[user_id] || "";
    const totalRequired = getRequiredTotal(programId, departments);
    const remained = Math.max(0.0, totalRequired - cumCredits);

    let programName = "";
    if (programId && departments) {
        const pId = programId.toLowerCase().trim();
        for (const dept of departments) {
            for (const p of (dept.programs || [])) {
                if (p.id?.toLowerCase() === pId) {
                    programName = p.name || "";
                    break;
                }
            }
            if (programName) break;
        }
    }

    const payload = {
        user_id,
        semesters: semestersList,
        cgpa: Number(cgpa.toFixed(2)),
        total_credits_earned: Number(cumCredits.toFixed(1)),
        remained_credits: Number(remained.toFixed(1)),
        program_name: programName,
        last_updated: new Date().toISOString()
    };

    await supabase.from("academic_data").upsert(payload);
    return { status: "ok", credits: cumCredits, cgpa: Number(cgpa.toFixed(2)) };
}

async function triggerSync(url: string, key: string, payload: any) {
    try {
        const res = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${key}`
            },
            body: JSON.stringify(payload)
        });
        return await res.json();
    } catch (e) {
        return { error: e.message };
    }
}

serve(async (req: Request) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

    try {
        const { secret, type, action, user_id } = await req.json();
        const adminPassword = Deno.env.get('ADMIN_PASSWORD');

        if (!secret || secret !== adminPassword) {
            return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: corsHeaders });
        }

        const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
        const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
        const supabase = createClient(supabaseUrl, supabaseKey);

        const targetAction = action || 'academic'; // fallback to academic for backward compatibility

        if (targetAction === 'academic') {
            const { data: metaData } = await supabase.from("course_metadata").select("code, name, credits, credit_val");
            const creditMap: Record<string, number> = {};
            const nameMap: Record<string, string> = {};
            (metaData || []).forEach((row: any) => {
                const code = (row.code || "").toUpperCase().replace(/\s+/g, "");
                nameMap[code] = row.name || code;
                let val = row.credit_val || row.credits || "3";
                creditMap[code] = parseFloat(String(val)) || 3.0;
            });
            const { data: depts } = await supabase.from("departments").select("programs");
            const { data: profiles } = await supabase.from("profiles").select("id, program_id");
            const profilesMap: Record<string, string> = {};
            (profiles || []).forEach((p: any) => profilesMap[p.id] = p.program_id);

            if (type === 'bulk') {
                const { data: allUsers } = await supabase.from("academic_data").select("user_id");
                let count = 0;
                for (const user of (allUsers || [])) {
                    try { await repairAcademicData(supabase, user.user_id, creditMap, nameMap, depts || [], profilesMap); count++; } catch (e) { console.error(e); }
                }
                return new Response(JSON.stringify({ status: "ok", message: `Bulk academic repair completed for ${count} users.` }), { headers: corsHeaders });
            } else {
                if (!user_id) throw new Error("user_id is required");
                const res = await repairAcademicData(supabase, user_id, creditMap, nameMap, depts || [], profilesMap);
                return new Response(JSON.stringify(res), { headers: corsHeaders });
            }
        }

        else if (targetAction === 'schedule' || targetAction === 'exams') {
            const endpoint = targetAction === 'schedule' ? 'sync-schedule' : 'match-exams';
            const url = `${supabaseUrl}/functions/v1/${endpoint}`;

            if (type === 'bulk') {
                const { data: profiles } = await supabase.from("profiles").select("id, enrolled_sections");
                let count = 0;
                for (const p of (profiles || [])) {
                    if (p.enrolled_sections && p.enrolled_sections.length > 0) {
                        await triggerSync(url, supabaseKey, { user_id: p.id });
                        count++;
                    }
                }
                return new Response(JSON.stringify({ status: "ok", message: `Bulk ${targetAction} sync completed for ${count} active users.` }), { headers: corsHeaders });
            } else {
                if (!user_id) throw new Error("user_id is required");
                const res = await triggerSync(url, supabaseKey, { user_id });
                return new Response(JSON.stringify(res), { headers: corsHeaders });
            }
        }

        return new Response(JSON.stringify({ error: "Invalid action" }), { status: 400, headers: corsHeaders });

    } catch (error) {
        return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: corsHeaders });
    }
});
