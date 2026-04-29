import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function predictGrade(percentage: number): [string, number] {
    if (percentage >= 80) return ["A+", 4.00];
    if (percentage >= 75) return ["A", 3.75];
    if (percentage >= 70) return ["A-", 3.50];
    if (percentage >= 65) return ["B+", 3.25];
    if (percentage >= 60) return ["B", 3.00];
    if (percentage >= 55) return ["B-", 2.75];
    if (percentage >= 50) return ["C+", 2.50];
    if (percentage >= 45) return ["C", 2.25];
    if (percentage >= 40) return ["D", 2.00];
    return ["F", 0.00];
}

function calculateCourseScore(courseData: any) {
    const distribution = courseData.distribution || {};
    const obtained = courseData.obtained || {};
    const config = courseData.markConfig || {};

    let totalObtained = 0.0;
    let totalMax = 0.0;
    const breakdown = [];

    for (const [component, weightVal] of Object.entries(distribution)) {
        if (weightVal === null || weightVal === undefined) continue;
        const weight = parseFloat(String(weightVal));
        const val = obtained[component];

        const compMax = weight;
        let compObtained = 0.0;

        if (Array.isArray(val)) {
            const listVal = val
                .map(x => parseFloat(String(x)))
                .filter(x => !isNaN(x));

            if (listVal.length > 0) {
                const compConfig = config[component] || {};
                const strategy = compConfig.strategy || "average";
                const outOf = parseFloat(String(compConfig.outOf || 10.0));

                if (strategy === "bestN") {
                    const n = parseInt(String(compConfig.n || 1));
                    const best = [...listVal].sort((a, b) => b - a).slice(0, n);
                    const avgRaw = best.reduce((a, b) => a + b, 0) / best.length;
                    compObtained = (avgRaw / outOf) * weight;
                } else if (strategy === "average") {
                    const avgRaw = listVal.reduce((a, b) => a + b, 0) / listVal.length;
                    compObtained = (avgRaw / outOf) * weight;
                } else if (strategy === "sum") {
                    let scale = parseFloat(String(compConfig.scaleFactor || 1.0));
                    if (compConfig.scaleFactor === undefined && outOf > 0) {
                        const totalN = parseInt(String(compConfig.totalN || listVal.length));
                        if (totalN > 0) {
                            scale = weight / (totalN * outOf);
                        }
                    }
                    compObtained = listVal.reduce((a, b) => a + b, 0) * scale;
                } else {
                    compObtained = (listVal.reduce((a, b) => a + b, 0) / listVal.length) || 0.0;
                }
            }
        } else if (val !== null && val !== undefined) {
            compObtained = parseFloat(String(val));
        }

        compObtained = Math.min(compObtained, compMax);
        totalObtained += compObtained;
        totalMax += compMax;
        breakdown.push({
            name: component,
            max: compMax,
            obtained: Number(compObtained.toFixed(2))
        });
    }

    const pct = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
    return { totalObtained, totalMax, pct, breakdown };
}

// Helper to get grade point based on modern scale
function getGradePoint(percentage: number): number {
    if (percentage >= 80) return 4.00;
    if (percentage >= 75) return 3.75;
    if (percentage >= 70) return 3.50;
    if (percentage >= 65) return 3.25;
    if (percentage >= 60) return 3.00;
    if (percentage >= 55) return 2.75;
    if (percentage >= 50) return 2.50;
    if (percentage >= 45) return 2.25;
    if (percentage >= 40) return 2.00;
    return 0.00;
}

function semSortKey(semStr: string): number {
    const match = semStr.match(/(Spring|Summer|Fall)\s*(\d{4})/i);
    if (!match) return 0;
    const term = match[1].toLowerCase();
    const year = parseInt(match[2]);
    const termOrder: Record<string, number> = { "spring": 1, "summer": 2, "fall": 3 };
    return year * 10 + (termOrder[term] || 0);
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
        const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
        const supabase = createClient(supabaseUrl, supabaseKey);

        const { user_id, semester_code } = await req.json();
        if (!user_id || !semester_code) throw new Error("user_id and semester_code are required");

        // 1. Concurrent fetching of all needed data
        const [progressRes, acadRes, profileRes, rulesRes, metaRes] = await Promise.all([
            supabase.from("semester_progress").select("*").eq("user_id", user_id).eq("semester_code", semester_code).maybeSingle(),
            supabase.from("academic_data").select("*").eq("user_id", user_id).maybeSingle(),
            supabase.from("profiles").select("student_id, semester_type, program_id, department").eq("id", user_id).single(),
            supabase.from("scholarship_rules").select("*"),
            supabase.from("course_metadata").select("code, credits, credit_val, equivalent_code")
        ]);

        if (!progressRes.data) return new Response(JSON.stringify({ status: "no_data" }), { headers: corsHeaders });

        const history = acadRes.data || { semesters: [], cgpa: 0, total_credits_earned: 0 };
        const profile = profileRes.data;
        const metaData = metaRes.data || [];
        const progressRaw = progressRes.data;

        // 2. Build credit lookup
        const creditMap: Record<string, number> = {};
        metaData.forEach(r => {
            const code = (r.code || "").toUpperCase().replace(/\s+/g, "");
            const val = r.credit_val || r.credits || 3;
            creditMap[code] = parseFloat(String(val)) || 3.0;
        });

        // 3. Calculate Current Semester Projection
        const summary = progressRaw.summary || { courses: {} };
        const coursesMap = summary.courses || {};
        
        let livePoints = 0.0;
        let goalPoints = 0.0;
        let currentCredits = 0.0;
        const courseDetails = [];

        for (const [code, data] of Object.entries(coursesMap)) {
            const cleanCode = code.toUpperCase().replace(/\s+/g, "");
            const credits = creditMap[cleanCode] || 3.0;
            const courseData = data as any;

            const { totalObtained, totalMax, pct } = calculateCourseScore(courseData);
            const liveGp = getGradePoint(pct);
            
            // Goal logic
            const goalGrade = courseData.gradeGoal || "B";
            // Map goal string to point - assume same scale for ongoing
            const goalGp = liveGp; // Fallback or logic to map "A+" to 4.0

            livePoints += liveGp * credits;
            currentCredits += credits;

            courseDetails.push({
                code: cleanCode,
                credits,
                liveMarks: Number(pct.toFixed(2)),
                liveGp,
                goal: goalGrade,
                isSet: (courseData.distribution && Object.keys(courseData.distribution).length > 0)
            });
        }

        const liveSGPA = currentCredits > 0 ? livePoints / currentCredits : 0.0;

        // 4. Calculate Cumulative CGPA
        // History points
        const pastPoints = (history.cgpa || 0) * (history.total_credits_earned || 0);
        const pastCredits = (history.total_credits_earned || 0);

        const cumulativeCredits = pastCredits + currentCredits;
        const liveCGPA = cumulativeCredits > 0 ? (pastPoints + livePoints) / cumulativeCredits : 0.0;

        // 5. Scholarship Projection (Annual Cycle)
        const isBi = profile.semester_type === 'bi';
        const cycleLength = isBi ? 2 : 3;

        // Admisson logic
        const idParts = (profile.student_id || "").split('-');
        const admitYear = parseInt(idParts[0]) || 2024;
        const admitTerm = parseInt(idParts[1]) || 2;
        const admitSortKey = admitYear * 10 + admitTerm;

        // Find relevant past semesters within this cycle
        const pastCompleted = (history.semesters || []).filter((s: any) => semSortKey(s.semesterName) >= admitSortKey);
        const pastSemsCount = pastCompleted.length;
        const currentCycleIndex = Math.floor(pastSemsCount / cycleLength);
        const semInCycle = (pastSemsCount % cycleLength) + 1;
        const remainingInCycle = cycleLength - semInCycle;

        const cycleStartIdx = currentCycleIndex * cycleLength;
        let cyclePoints = 0.0;
        let cycleCredits = 0.0;
        for (let i = cycleStartIdx; i < pastCompleted.length; i++) {
            const sem = pastCompleted[i];
            cyclePoints += (sem.termGPA || 0) * (sem.totalCredits || 0);
            cycleCredits += (sem.totalCredits || 0);
        }

        const totalCyclePointsLive = cyclePoints + livePoints;
        const totalCycleCredits = cycleCredits + currentCredits;
        const liveYearlyGPA = totalCycleCredits > 0 ? totalCyclePointsLive / totalCycleCredits : 0.0;

        // Scholarship Rule
        const programId = (profile.department || profile.program_id || "").toLowerCase();
        const rule = (rulesRes.data || []).find((r: any) => r.program_id.toLowerCase() === programId) || {
            tier_medha_lalon_min: 3.50,
            tier_deans_list_min: 3.75,
            tier_merit_100_min: 3.90,
            annual_credits_required: isBi ? 21.0 : 30.0
        };

        const thresholds = [
            { name: "Medha Lalon", min: parseFloat(rule.tier_medha_lalon_min) },
            { name: "Dean's List", min: parseFloat(rule.tier_deans_list_min) },
            { name: "100% Merit", min: parseFloat(rule.tier_merit_100_min) }
        ];

        const tierProjections = thresholds.map(t => {
            let reqSGPA: number | null = null;
            let status = "ongoing";
            
            if (liveYearlyGPA >= t.min) {
                status = "achieved";
            } else if (remainingInCycle === 0) {
                // Last semester of cycle
                const totalPointsNeeded = t.min * totalCycleCredits;
                const pointsNeededNow = totalPointsNeeded - cyclePoints;
                reqSGPA = currentCredits > 0 ? pointsNeededNow / currentCredits : 0;
                if (reqSGPA > 4.0) status = "impossible";
                else if (reqSGPA <= 0) status = "achieved";
            } else {
                // More semesters left
                const estFutureCredits = 15.0;
                const totalProjCredits = totalCycleCredits + (remainingInCycle * estFutureCredits);
                const totalPointsNeeded = t.min * totalProjCredits;
                const pointsNeededFuture = totalPointsNeeded - (cyclePoints + livePoints);
                reqSGPA = (remainingInCycle * estFutureCredits) > 0 ? pointsNeededFuture / (remainingInCycle * estFutureCredits) : 0;
                if (reqSGPA > 4.0) status = "impossible";
            }

            return { name: t.name, min: t.min, reqSGPA, status };
        });

        // 6. Update Summary
        const analytics = {
            liveSGPA: Number(liveSGPA.toFixed(2)),
            liveCGPA: Number(liveCGPA.toFixed(2)),
            liveYearlyGPA: Number(liveYearlyGPA.toFixed(2)),
            cycleName: `Year ${currentCycleIndex + 1} (${semInCycle}/${cycleLength})`,
            semInCycle,
            remainingInCycle,
            tierProjections,
            credits: {
                earned: history.total_credits_earned || 0,
                current: currentCredits,
                cycleEarned: totalCycleCredits,
                cycleGoal: parseFloat(rule.annual_credits_required)
            }
        };

        summary.analytics = analytics;
        summary.courseDetails = courseDetails;

        const { error: updateError } = await supabase.from("semester_progress").upsert({
            user_id,
            semester_code,
            summary,
            last_updated: new Date().toISOString()
        });

        if (updateError) throw updateError;

        // 7. Sync to dedicated Analytics Table
        const { error: analyticsError } = await supabase.from("semester_summary_analytics").upsert({
            user_id,
            semester_code,
            live_sgpa: analytics.liveSGPA,
            live_cgpa: analytics.liveCGPA,
            scholarship_gpa: analytics.liveYearlyGPA,
            cycle_info: analytics.cycleName,
            sem_in_cycle: analytics.semInCycle,
            total_sem_in_cycle: cycleLength,
            earned_credits: analytics.credits.earned,
            cycle_earned_credits: analytics.credits.cycleEarned,
            cycle_goal_credits: analytics.credits.cycleGoal,
            tier_projections: analytics.tierProjections,
            updated_at: new Date().toISOString()
        });

        if (analyticsError) console.error("Error syncing to scholarship_analytics:", analyticsError);

        return new Response(JSON.stringify({
            status: "ok",
            analytics
        }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });

    } catch (error) {
        console.error(error);
        return new Response(JSON.stringify({ error: error.message }), { headers: corsHeaders, status: 500 });
    }
});
