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

        // 1. Fetch semester progress row
        const { data: row } = await supabase
            .from("semester_progress")
            .select("*")
            .eq("user_id", user_id)
            .eq("semester_code", semester_code)
            .maybeSingle();

        if (!row) return new Response(JSON.stringify({ status: "no_data", message: "No semester progress found" }), { headers: corsHeaders });

        const summary = row.summary || {};
        const coursesMap = summary.courses || {};

        if (Object.keys(coursesMap).length === 0) {
            return new Response(JSON.stringify({ status: "no_courses" }), { headers: corsHeaders });
        }

        // 2. Build credit lookup
        const { data: metaData } = await supabase.from("course_metadata").select("code, credits, credit_val");
        const creditMap: Record<string, number> = {};
        (metaData || []).forEach(r => {
            const code = (r.code || "").toUpperCase().replace(/\s+/g, "");
            const val = r.credit_val || r.credits || 3;
            creditMap[code] = parseFloat(String(val)) || 3.0;
        });

        // 3. Calculate each course
        let totalGpCredits = 0.0;
        let totalCredits = 0.0;
        const courseSummaries = [];

        for (const [code, courseData] of Object.entries(coursesMap)) {
            const cleanCode = code.toUpperCase().replace(/\s+/g, "");
            const credits = creditMap[cleanCode] || 3.0;

            const { totalObtained, totalMax, pct, breakdown } = calculateCourseScore(courseData);
            const [grade, gpa] = predictGrade(pct);

            totalGpCredits += gpa * credits;
            totalCredits += credits;

            courseSummaries.push({
                courseCode: cleanCode,
                credits,
                percentage: Number(pct.toFixed(2)),
                grade,
                gpa,
                obtained: Number(totalObtained.toFixed(2)),
                max: Number(totalMax.toFixed(2)),
                breakdown
            });
        }

        const sgpa = totalCredits > 0 ? totalGpCredits / totalCredits : 0.0;

        // 4. Update Database
        summary.sgpa = Number(sgpa.toFixed(2));
        summary.totalCredits = totalCredits;
        summary.courseSummaries = courseSummaries;

        const { error: updateError } = await supabase.from("semester_progress").upsert({
            user_id,
            semester_code,
            summary
        });

        if (updateError) throw updateError;

        return new Response(JSON.stringify({
            status: "ok",
            sgpa: Number(sgpa.toFixed(2)),
            courses: courseSummaries.length
        }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });

    } catch (error) {
        console.error(error);
        return new Response(JSON.stringify({ error: error.message }), { headers: corsHeaders, status: 500 });
    }
});
