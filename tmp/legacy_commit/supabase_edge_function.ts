import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-client@2";

serve(async (req) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const body = await req.json();
    const userId = body.record?.user_id || body.user_id;
    
    if (!userId) throw new Error("Missing user_id");

    // 1. Fetch Grade Scale Configuration
    const { data: scales, error: scaleError } = await supabase
      .from('grade_scale')
      .select('grade, point, policy');
    if (scaleError) throw scaleError;

    // Helper to get grade point from scale
    const getGradePoint = (grade: string, semesterCode: string) => {
      let year: number;
      let season: string;
      const lowerSem = semesterCode.toLowerCase();

      if (lowerSem.includes('_')) {
        const parts = lowerSem.split('_');
        year = parseInt(parts[1]);
        season = parts[0];
      } else {
        year = parseInt(lowerSem.replace(/[^0-9]/g, ''));
        season = lowerSem.replace(/[0-9]/g, '');
      }

      let policy = 'modern';
      if (year < 2023) {
        policy = 'legacy';
      } else if (year === 2023) {
        if (['spring', 'summer'].includes(season)) {
          policy = 'legacy';
        }
      }

      const match = scales.find(s => s.grade === grade && s.policy === policy);
      return match ? Number(match.point) : 0;
    };

    // 2. Fetch all completed courses for this user
    const { data: courses, error: fetchError } = await supabase
      .from('completed_courses')
      .select('*')
      .eq('user_id', userId)
      .order('semester_code', { ascending: true });
    if (fetchError) throw fetchError;

    // 3. Chronological Analytics
    const semesterMap: Record<string, any> = {};
    const semestersList: any[] = [];
    
    let cumulativePoints = 0;
    let cumulativeCredits = 0;

    for (const course of courses) {
      const semCode = course.semester_code;
      if (!semesterMap[semCode]) {
        semesterMap[semCode] = { 
          user_id: userId,
          semester_code: semCode, 
          courses: [], 
          tgpa: 0, 
          credits_earned: 0,
          cgpa: 0,
          total_credits_earned: 0
        };
        semestersList.push(semesterMap[semCode]);
      }

      const point = getGradePoint(course.grade, semCode);
      const credits = Number(course.credits);

      semesterMap[semCode].courses.push({
        code: course.course_code,
        grade: course.grade,
        credits: credits,
        point: point
      });

      // CGPA Calculation Rules: 
      // Exclude W, I, P, S, U, R from points and credits denominator
      const isExcluded = ['W', 'I', 'P', 'S', 'U', 'R'].includes(course.grade);
      
      if (!isExcluded) {
        cumulativePoints += (point * credits);
        cumulativeCredits += credits;
        semesterMap[semCode].credits_earned += credits;
      }
      
      semesterMap[semCode].cgpa = cumulativeCredits > 0 ? Number((cumulativePoints / cumulativeCredits).toFixed(2)) : 0;
      semesterMap[semCode].total_credits_earned = cumulativeCredits;
    }

    // TGPA Calculation
    for (const sem of semestersList) {
      let semPoints = 0;
      let semCredits = 0;
      for (const c of sem.courses) {
        const isExcl = ['W', 'I', 'P', 'S', 'U', 'R'].includes(c.grade);
        if (!isExcl) {
          semPoints += (c.point * c.credits);
          semCredits += c.credits;
        }
      }
      sem.tgpa = semCredits > 0 ? Number((semPoints / semCredits).toFixed(2)) : 0;
    }

    // 4. Sync semester_summaries table
    const summaryIds: string[] = [];
    for (const sem of semestersList) {
      const { data: upserted, error: upsertError } = await supabase
        .from('semester_summaries')
        .upsert({
          user_id: sem.user_id,
          semester_code: sem.semester_code,
          courses: sem.courses,
          tgpa: sem.tgpa,
          cgpa: sem.cgpa,
          credits_earned: sem.credits_earned,
          total_credits_earned: sem.total_credits_earned,
          updated_at: new Date().toISOString()
        }, { onConflict: 'user_id, semester_code' })
        .select('id')
        .single();
      
      if (upsertError) throw upsertError;
      summaryIds.push(upserted.id);
    }

    // 5. Update Profile
    const finalCgpa = semestersList.length > 0 ? semestersList[semestersList.length - 1].cgpa : 0;
    const { error: profileError } = await supabase
      .from('profiles')
      .update({ 
        past_history: summaryIds, // Store List of Summary UUIDs
        cgpa: finalCgpa,
        total_credits_earned: cumulativeCredits
      })
      .eq('id', userId);
    if (profileError) throw profileError;

    return new Response(JSON.stringify({ success: true, count: semestersList.length, cgpa: finalCgpa }), { headers: { "Content-Type": "application/json" } });

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});
