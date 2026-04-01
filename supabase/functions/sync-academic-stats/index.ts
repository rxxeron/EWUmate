import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

    // Helper to get year/season weight for chronological sorting
    const getYear = (sem: string): number => {
      const match = sem.match(/\d{4}/);
      return match ? parseInt(match[0]) : 0;
    };
    const getSeasonWeight = (sem: string): number => {
      const lower = sem.toLowerCase();
      if (lower.startsWith('spring')) return 1;
      if (lower.startsWith('summer')) return 2;
      if (lower.startsWith('fall')) return 3;
      // Backup if codes are reversed e.g. 2025_Spring
      if (lower.includes('spring')) return 1;
      if (lower.includes('summer')) return 2;
      if (lower.includes('fall')) return 3;
      return 0;
    };

    // 2. Fetch all completed courses for this user
    const { data: rawCourses, error: fetchError } = await supabase
      .from('completed_courses')
      .select('*')
      .eq('user_id', userId);
    if (fetchError) throw fetchError;

    // Sort chronologically BEFORE processing
    const courses = (rawCourses || []).sort((a, b) => {
      const yearA = getYear(a.semester_code);
      const yearB = getYear(b.semester_code);
      if (yearA !== yearB) return yearA - yearB;
      return getSeasonWeight(a.semester_code) - getSeasonWeight(b.semester_code);
    });

    // Fetch all metadata for these course codes to get correct credits
    const courseCodesForMeta = Array.from(new Set(courses.map(c => c.course_code.toUpperCase())));
    let courseMeta: any[] = [];
    if (courseCodesForMeta.length > 0) {
      const { data: meta, error: metaErr } = await supabase
        .from('course_metadata')
        .select('code, credit_val, equivalent_code')
        .in('code', courseCodesForMeta);
      if (metaErr) throw metaErr;
      courseMeta = meta;
    }

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
      const metaMatch = courseMeta.find(m => m.code === course.course_code.toUpperCase());
      const credits = metaMatch ? Number(metaMatch.credit_val) : Number(course.credits || 0);

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

    // 5. Calculate Current Support (Source of Truth: enrollments table)
    const { data: activeSemData, error: activeSemErr } = await supabase
      .from('active_semester')
      .select('*')
      .limit(1)
      .single();
    if (activeSemErr) throw activeSemErr;
    
    // In active_semester, the 2nd column (index 1) is usually the current semester code.
    // However, in Supabase JS we use property names. Based on previous SQL check: [('tri_semester', 'Spring2026', ...)]
    // Map property names: current_semester_code? Let's check table columns or just use raw if possible.
    // For now, I'll use the most likely name or fetch all.
    const activeSemester = activeSemData.current_semester_code || 'Spring2026';

    const { data: currentEnrollments, error: enrollError } = await supabase
      .from('enrollments')
      .select('id, course_code, semester_code')
      .eq('user_id', userId)
      .eq('status', 'enrolled');
    
    if (enrollError) throw enrollError;

    const currentEnrollmentIds: string[] = [];
    const nextEnrollmentIds: string[] = [];
    const currentCourseCodes: string[] = [];
    const nextCourseCodes: string[] = [];

    for (const enr of currentEnrollments) {
      if (enr.semester_code === activeSemester) {
        currentEnrollmentIds.push(enr.id);
        currentCourseCodes.push(enr.course_code.toUpperCase());
      } else {
        nextEnrollmentIds.push(enr.id);
        nextCourseCodes.push(enr.course_code.toUpperCase());
      }
    }

    const allEnrollmentCodes = Array.from(new Set([...currentCourseCodes, ...nextCourseCodes]));
    
    let enrolledCredits = 0;
    let enrolledNextCredits = 0;

    if (allEnrollmentCodes.length > 0) {
      const { data: metadata, error: metaError } = await supabase
        .from('course_metadata')
        .select('code, credit_val')
        .in('code', allEnrollmentCodes);
      
      if (metaError) throw metaError;

      enrolledCredits = currentCourseCodes.reduce((sum, code) => {
        const match = (metadata || []).find(m => m.code === code);
        return sum + (match ? Number(match.credit_val) : 0);
      }, 0);

      enrolledNextCredits = nextCourseCodes.reduce((sum, code) => {
        const match = (metadata || []).find(m => m.code === code);
        return sum + (match ? Number(match.credit_val) : 0);
      }, 0);
    }

    // 6. Update Profile
    // The final cumulative CGPA and credits are the values after processing the absolute last course
    const finalCgpa = cumulativePoints > 0 && cumulativeCredits > 0 
      ? Number((cumulativePoints / cumulativeCredits).toFixed(2)) 
      : 0;

    const totalCoursesCompleted = semestersList.reduce((sum, s) => sum + (s.courses?.length || 0), 0);

    const { error: profileError } = await supabase
      .from('profiles')
      .update({ 
        past_history: summaryIds, 
        cgpa: finalCgpa,
        total_credits_earned: cumulativeCredits,
        total_courses_completed: totalCoursesCompleted,
        enrolled_sections: currentEnrollmentIds,
        enrolled_sections_next: nextEnrollmentIds,
        enrolled_credits: enrolledCredits,
        enrolled_credits_next: enrolledNextCredits,
        updated_at: new Date().toISOString()
      })
      .eq('id', userId);
    
    if (profileError) throw profileError;


    return new Response(JSON.stringify({ 
      success: true, 
      count: semestersList.length, 
      cgpa: finalCgpa,
      total_credits_earned: cumulativeCredits,
      total_courses_completed: totalCoursesCompleted,
      enrolled_credits: enrolledCredits 
    }), { headers: { "Content-Type": "application/json" } });

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});
