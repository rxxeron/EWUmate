import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type TriggerJob = {
  id: string;
  job_type: string;
  user_id: string;
  semester_id: string | null;
  payload: Record<string, unknown> | null;
};

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: { persistSession: false },
});

const WEEK_DAYS = [
  "Sunday",
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
];

function emptyWeek() {
  return WEEK_DAYS.reduce<Record<string, unknown[]>>((acc, day) => {
    acc[day] = [];
    return acc;
  }, {});
}

function parseTimeToMinutes(timeStr?: string | null) {
  if (!timeStr) return null;
  const trimmed = timeStr.trim().toUpperCase();
  const ampmMatch = trimmed.match(/(\d{1,2}):(\d{2})\s*(AM|PM)/);
  if (ampmMatch) {
    const hours = parseInt(ampmMatch[1], 10) % 12;
    const minutes = parseInt(ampmMatch[2], 10);
    const suffix = ampmMatch[3];
    return (hours + (suffix === "PM" ? 12 : 0)) * 60 + minutes;
  }

  const simpleMatch = trimmed.match(/(\d{1,2}):(\d{2})/);
  if (!simpleMatch) return null;
  const hours = parseInt(simpleMatch[1], 10);
  const minutes = parseInt(simpleMatch[2], 10);
  return hours * 60 + minutes;
}

function parseDays(dayStr?: string | null) {
  if (!dayStr) return [] as string[];
  const dayMap: Record<string, string> = {
    S: "Sunday",
    SU: "Sunday",
    SUN: "Sunday",
    M: "Monday",
    MO: "Monday",
    MON: "Monday",
    T: "Tuesday",
    TU: "Tuesday",
    TUE: "Tuesday",
    W: "Wednesday",
    WE: "Wednesday",
    WED: "Wednesday",
    R: "Thursday",
    TH: "Thursday",
    THU: "Thursday",
    F: "Friday",
    FR: "Friday",
    FRI: "Friday",
    A: "Saturday",
    SA: "Saturday",
    SAT: "Saturday",
  };

  const tokens = Object.keys(dayMap).sort((a, b) => b.length - a.length);
  const normalized = dayStr.toUpperCase().replace(/\s+/g, "");
  const result = new Set<string>();

  let i = 0;
  while (i < normalized.length) {
    let matched = false;
    for (const token of tokens) {
      if (normalized.startsWith(token, i)) {
        result.add(dayMap[token]);
        i += token.length;
        matched = true;
        break;
      }
    }
    if (!matched) i += 1;
  }

  return Array.from(result);
}

async function rebuildWeeklySchedule(userId: string, semesterId: string) {
  const { data: userRow, error: userError } = await supabase
    .from("users")
    .select("enrolled_sections")
    .eq("uid", userId)
    .single();

  if (userError) throw userError;

  const enrolledSections = (userRow?.enrolled_sections ?? []) as string[];

  if (!enrolledSections.length) {
    const empty = emptyWeek();
    await supabase.from("user_schedules").upsert({
      user_id: userId,
      doc_id: semesterId,
      weekly_template: empty,
      last_updated: new Date().toISOString(),
    });

    await supabase.from("users").update({ weekly_schedule: empty }).eq("uid", userId);
    return;
  }

  const { data: courseRows, error: courseError } = await supabase
    .from("courses")
    .select("doc_id, code, course_name, sessions")
    .eq("semester_id", semesterId)
    .in("doc_id", enrolledSections);

  if (courseError) throw courseError;

  const weeklyTemplate = emptyWeek();

  for (const course of courseRows ?? []) {
    const sessions = (course.sessions ?? []) as Array<Record<string, unknown>>;
    for (const sess of sessions) {
      const daysStr = String(sess.day ?? "").toUpperCase();
      const foundDays = parseDays(daysStr);
      for (const day of foundDays) {
        (weeklyTemplate[day] as Array<Record<string, unknown>>).push({
          courseCode: course.code,
          courseName: course.course_name,
          startTime: sess.startTime,
          endTime: sess.endTime,
          room: sess.room ?? "TBA",
          type: sess.type ?? "Theory",
          faculty: sess.faculty ?? "",
        });
      }
    }
  }

  for (const day of WEEK_DAYS) {
    (weeklyTemplate[day] as Array<Record<string, unknown>>).sort((a, b) => {
      const aTime = parseTimeToMinutes(String(a.startTime ?? "")) ?? 0;
      const bTime = parseTimeToMinutes(String(b.startTime ?? "")) ?? 0;
      return aTime - bTime;
    });
  }

  const { data: calendarRows, error: calendarError } = await supabase
    .from("calendar_events")
    .select("date, event")
    .eq("semester_id", semesterId);

  if (calendarError) throw calendarError;

  const holidays: Array<Record<string, unknown>> = [];
  const daySwaps: Array<Record<string, unknown>> = [];

  for (const evt of calendarRows ?? []) {
    const content = String(evt.event ?? "").toLowerCase();
    const dateStr = String(evt.date ?? "");

    if (content.includes("holiday")) {
      holidays.push({ date: dateStr, name: evt.event ?? "Holiday" });
    }

    const swapMatch = content.match(
      /(sunday|monday|tuesday|wednesday|thursday|friday|saturday)\s+classes?/
    );
    if (swapMatch) {
      daySwaps.push({
        date: dateStr,
        actsAs: swapMatch[1].charAt(0).toUpperCase() + swapMatch[1].slice(1),
        reason: evt.event ?? "",
      });
    }
  }

  await supabase.from("user_schedules").upsert({
    user_id: userId,
    doc_id: semesterId,
    weekly_template: weeklyTemplate,
    holidays,
    day_swaps: daySwaps,
    last_updated: new Date().toISOString(),
  });

  const simplifiedSchedule = emptyWeek();
  for (const day of WEEK_DAYS) {
    for (const cls of weeklyTemplate[day] as Array<Record<string, unknown>>) {
      (simplifiedSchedule[day] as Array<Record<string, unknown>>).push({
        title: cls.courseName,
        courseCode: cls.courseCode,
        time: `${cls.startTime}-${cls.endTime}`,
        room: cls.room,
      });
    }
  }

  await supabase
    .from("users")
    .update({ weekly_schedule: simplifiedSchedule })
    .eq("uid", userId);
}

function calculateCourseScore(courseData: Record<string, unknown>) {
  const distribution = (courseData.distribution ?? {}) as Record<string, unknown>;
  const obtained = (courseData.obtained ?? {}) as Record<string, unknown>;
  const config = (courseData.markConfig ?? {}) as Record<string, unknown>;

  let totalObtained = 0;
  let totalMax = 0;
  const breakdown: Array<Record<string, unknown>> = [];

  for (const [component, weightValue] of Object.entries(distribution)) {
    if (weightValue == null) continue;
    const weight = Number(weightValue);
    const value = obtained[component];

    let compObtained = 0;
    let compMax = weight;

    if (Array.isArray(value)) {
      const listVal = value.filter((x) => x != null).map((x) => Number(x));
      if (listVal.length) {
        const compConfig = (config[component] ?? {}) as Record<string, unknown>;
        const strategy = String(compConfig.strategy ?? "average");
        const outOf = Number(compConfig.outOf ?? 10);

        if (strategy === "bestN") {
          const n = Number(compConfig.n ?? 1);
          const sortedVals = [...listVal].sort((a, b) => b - a);
          const bestN = sortedVals.slice(0, n);
          const avgRaw = bestN.reduce((sum, v) => sum + v, 0) / bestN.length;
          compObtained = (avgRaw / outOf) * weight;
        } else if (strategy === "sum") {
          let scale = Number(compConfig.scaleFactor ?? 1);
          if (!compConfig.scaleFactor && outOf > 0) {
            const totalN = Number(compConfig.totalN ?? listVal.length);
            if (totalN > 0) {
              scale = weight / (totalN * outOf);
            }
          }
          compObtained = listVal.reduce((sum, v) => sum + v, 0) * scale;
        } else {
          const avgRaw = listVal.reduce((sum, v) => sum + v, 0) / listVal.length;
          compObtained = (avgRaw / outOf) * weight;
        }
      }
    } else {
      compObtained = value == null ? 0 : Number(value);
    }

    compObtained = Math.min(compObtained, compMax);
    totalObtained += compObtained;
    totalMax += compMax;

    breakdown.push({
      name: component,
      max: compMax,
      obtained: Math.round(compObtained * 100) / 100,
    });
  }

  const percentage = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0;
  return { totalObtained, totalMax, percentage, breakdown };
}

function predictGrade(percentage: number) {
  if (percentage >= 80) return { grade: "A+", gpa: 4.0 };
  if (percentage >= 75) return { grade: "A", gpa: 3.75 };
  if (percentage >= 70) return { grade: "A-", gpa: 3.5 };
  if (percentage >= 65) return { grade: "B+", gpa: 3.25 };
  if (percentage >= 60) return { grade: "B", gpa: 3.0 };
  if (percentage >= 55) return { grade: "B-", gpa: 2.75 };
  if (percentage >= 50) return { grade: "C+", gpa: 2.5 };
  if (percentage >= 45) return { grade: "C", gpa: 2.25 };
  if (percentage >= 40) return { grade: "D", gpa: 2.0 };
  return { grade: "F", gpa: 0.0 };
}

async function updateSemesterSummary(userId: string, semesterId: string) {
  const { data: courseRows, error } = await supabase
    .from("user_semester_courses")
    .select("course_code, course_name, distribution, obtained, quiz_strategy, data")
    .eq("user_id", userId)
    .eq("semester_code", semesterId);

  if (error) throw error;

  let totalGpCredits = 0;
  let totalCredits = 0;
  const summaries: Array<Record<string, unknown>> = [];

  for (const row of courseRows ?? []) {
    const data = (row.data ?? {}) as Record<string, unknown>;
    const credits = Number((data as Record<string, unknown>).credits ?? 3);

    const courseData = {
      courseCode: row.course_code ?? data.courseCode,
      courseName: row.course_name ?? data.courseName,
      distribution: row.distribution ?? data.distribution ?? {},
      obtained: row.obtained ?? data.obtained ?? {},
      quizStrategy: row.quiz_strategy ?? data.quizStrategy,
      markConfig: data.markConfig ?? {},
    } as Record<string, unknown>;

    const { totalObtained, totalMax, percentage, breakdown } =
      calculateCourseScore(courseData);
    const { grade, gpa } = predictGrade(percentage);

    totalGpCredits += gpa * credits;
    totalCredits += credits;

    summaries.push({
      courseCode: courseData.courseCode,
      credits,
      percentage: Math.round(percentage * 100) / 100,
      grade,
      gpa,
      obtained: Math.round(totalObtained * 100) / 100,
      max: Math.round(totalMax * 100) / 100,
      breakdown,
    });
  }

  const sgpa = totalCredits > 0 ? totalGpCredits / totalCredits : 0;
  const summary = {
    sgpa: Math.round(sgpa * 100) / 100,
    totalCredits,
    lastUpdated: new Date().toISOString(),
    courseSummaries: summaries,
  };

  await supabase.from("user_semester_progress").upsert({
    user_id: userId,
    semester_code: semesterId,
    doc_id: semesterId,
    last_updated: new Date().toISOString(),
    summary,
    data: { summary },
  });
}

async function processJob(job: TriggerJob) {
  const semesterId = job.semester_id ?? "";
  if (job.job_type === "enrollment_change") {
    if (!semesterId) return;
    await rebuildWeeklySchedule(job.user_id, semesterId);
    return;
  }

  if (job.job_type === "course_marks_change") {
    if (!semesterId) return;
    await updateSemesterSummary(job.user_id, semesterId);
  }
}

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  const { data: jobs, error } = await supabase
    .from("trigger_jobs")
    .select("id, job_type, user_id, semester_id, payload")
    .is("processed_at", null)
    .order("created_at", { ascending: true })
    .limit(20);

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }

  for (const job of (jobs ?? []) as TriggerJob[]) {
    try {
      await processJob(job);
      await supabase
        .from("trigger_jobs")
        .update({ processed_at: new Date().toISOString(), status: "completed" })
        .eq("id", job.id);
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      await supabase
        .from("trigger_jobs")
        .update({ status: "failed", error: message })
        .eq("id", job.id);
    }
  }

  return new Response(JSON.stringify({ processed: jobs?.length ?? 0 }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
