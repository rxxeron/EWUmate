import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import postgres from 'https://deno.land/x/postgresjs@v3.3.4/mod.js';

// Using the correct DATABASE_URL from .env
const SUPABASE_DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres";

serve(async (req) => {
    const logs: string[] = [];
    const log = (msg: string) => {
        const timestamp = new Date().toISOString();
        const line = `[${timestamp}] ${msg}`;
        console.log(line);
        logs.push(line);
    };

    if (req.method !== 'POST') {
        return new Response('Method not allowed', { status: 405 });
    }

    log("Alert Scheduler (Fixed Connection) started");
    const sql = postgres(SUPABASE_DB_URL, { max: 1 });

    try {
        const profiles = await sql`SELECT id FROM profiles`;
        log(`Found ${profiles.length} profiles`);

        const [activeSem] = await sql`SELECT current_semester_code FROM active_semester LIMIT 1`;
        if (!activeSem) {
            log("No active semester found.");
            return new Response(JSON.stringify({ error: "No active semester", logs }), { status: 500 });
        }
        const semCode = activeSem.current_semester_code;
        const dbSem = semCode.replace(/\s/g, "");
        const safeSem = semCode.toLowerCase().replace(/\s/g, "");
        log(`Active Semester: ${semCode}`);

        const overrides = await sql`SELECT * FROM schedule_overrides WHERE is_active = true`;
        const overridesMap: Record<string, any> = {};
        overrides.forEach((o: any) => {
            const key = `${o.original_start}-${o.original_end}`;
            overridesMap[key] = o;
            if (!overridesMap[o.original_start]) overridesMap[o.original_start] = o;
        });

        const now = new Date();
        const dhakaTime = new Date(now.getTime() + (6 * 60 * 60 * 1000));
        log(`Dhaka Time: ${dhakaTime.toISOString()}`);

        for (const profile of profiles) {
            const userId = profile.id;
            try {
                log(`--- User: ${userId} ---`);
                const [schedule] = await sql`SELECT weekly_template FROM user_schedules WHERE user_id = ${userId} AND semester = ${dbSem}`;
                if (schedule && schedule.weekly_template) {
                    const template = schedule.weekly_template;
                    const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

                    for (let offset = 0; offset <= 1; offset++) {
                        const dhakaTarget = new Date(now.getTime() + (6 * 60 * 60 * 1000) + (offset * 24 * 60 * 60 * 1000));
                        const dayName = days[dhakaTarget.getUTCDay()];
                        const originalClasses = template[dayName] || [];

                        if (originalClasses.length === 0) continue;
                        log(`  ${dayName} (offset ${offset}) - ${originalClasses.length} classes`);

                        const classes = originalClasses.map((c: any) => ({
                            ...c,
                            startTime: overridesMap[c.startTime]?.new_start || c.startTime,
                            endTime: overridesMap[c.startTime]?.new_end || c.endTime
                        })).sort((a: any, b: any) => {
                            const ta = parseTime(a.startTime);
                            const tb = parseTime(b.startTime);
                            return (ta.h * 60 + ta.m) - (tb.h * 60 + tb.m);
                        });

                        for (let i = 0; i < classes.length; i++) {
                            const c = classes[i];
                            const time = parseTime(c.startTime);
                            const triggerUTC = new Date(Date.UTC(dhakaTarget.getUTCFullYear(), dhakaTarget.getUTCMonth(), dhakaTarget.getUTCDate(), time.h - 6, time.m, 0));
                            const venue = c.room || c.venue || 'TBA';
                            const dateStr = dhakaTarget.toISOString().split('T')[0];

                            if (i === 0) {
                                for (const m of [45, 30, 15]) {
                                    await scheduleAlert(sql, userId, new Date(triggerUTC.getTime() - m * 60000),
                                        `First Class: ${c.courseCode}`, `You have ${c.courseCode} at ${venue} within ${m} minutes`,
                                        `class_${m}m`, `c_${m}m:${c.courseCode}:${dateStr}`, log);
                                }
                            }

                            if (i > 0) {
                                const prev = classes[i - 1];
                                const pTime = parseTime(prev.endTime || prev.startTime);
                                const pEndUTC = new Date(Date.UTC(dhakaTarget.getUTCFullYear(), dhakaTarget.getUTCMonth(), dhakaTarget.getUTCDate(), pTime.h - 6, pTime.m, 0));
                                const gap = (triggerUTC.getTime() - pEndUTC.getTime()) / 60000;

                                if (gap <= 30) {
                                    const m = 5;
                                    await scheduleAlert(sql, userId, new Date(triggerUTC.getTime() - m * 60000),
                                        `Class Reminder: ${c.courseCode}`, `You have ${c.courseCode} at ${venue} within ${m} minutes`, "class_5m_short", `c_5m_sh:${c.courseCode}:${dateStr}`, log);
                                } else {
                                    for (const m of [30, 10]) {
                                        await scheduleAlert(sql, userId, new Date(triggerUTC.getTime() - m * 60000),
                                            `Class Reminder: ${c.courseCode}`, `You have ${c.courseCode} at ${venue} within ${m} minutes`, `class_${m}m_gap`, `c_${m}m_g:${c.courseCode}:${dateStr}`, log);
                                    }
                                }
                            }
                        }
                    }
                }

                const tasks = await sql`SELECT * FROM tasks WHERE user_id = ${userId} AND is_completed = false`;
                for (const t of tasks) {
                    const due = new Date(t.due_date);
                    for (const d of [3, 1]) {
                        const trig = new Date(due.getTime() - d * 24 * 3600000);
                        trig.setUTCHours(2, 0, 0, 0);
                        await scheduleAlert(sql, userId, trig, d === 1 ? "Due Tomorrow!" : "Task Update", t.title, `task_${d}d`, `t_${d}d:${t.id}`, log);
                    }
                }

                const exams = await sql`SELECT * FROM ${sql.unsafe(`exams_${safeSem}`)}`;
                if (exams.length > 0 && schedule && schedule.weekly_template) {
                    const unique = getUniqueCourses(schedule.weekly_template);
                    for (const [code, info] of Object.entries(unique)) {
                        const pat = getPattern(info.days);
                        const match = exams.find((e: any) => e.class_days === pat);
                        if (match) {
                            const [existing] = await sql`SELECT id FROM tasks WHERE user_id = ${userId} AND course_code = ${code} AND type = 'finalExam'`;
                            if (!existing) {
                                const eDate = parseTextDate(match.exam_date);
                                if (eDate && (eDate.getTime() - now.getTime()) / 86400000 <= 120) {
                                    await sql`INSERT INTO tasks (user_id, title, course_code, course_name, due_date, type, submission_type, is_completed) 
                                              VALUES (${userId}, ${`Final Exam: ${code}`}, ${code}, ${info.name}, ${eDate.toISOString()}, 'finalExam', 'offline', false)`;
                                    log(`  Exam Synced: ${code}`);
                                }
                            }
                        }
                    }
                }
            } catch (err: any) {
                log(`  Error: ${err.message}`);
            }
        }

        await sql.end();
        return new Response(JSON.stringify({ message: "Done", logs }), { status: 200 });
    } catch (err: any) {
        log(`Fatal: ${err.message}`);
        return new Response(JSON.stringify({ error: err.message, logs }), { status: 500 });
    }
});

async function scheduleAlert(sql: any, userId: string, trigger: Date, title: string, body: string, type: string, key: string, log: Function) {
    if (trigger < new Date()) return;
    try {
        await sql`INSERT INTO scheduled_alerts (user_id, trigger_at, title, body, type, alert_key, is_dispatched, metadata)
                  VALUES (${userId}, ${trigger.toISOString()}, ${title}, ${body}, ${type}, ${key}, false, ${{}})
                  ON CONFLICT (user_id, alert_key) DO UPDATE SET 
                  trigger_at = EXCLUDED.trigger_at, title = EXCLUDED.title, body = EXCLUDED.body`;
        log(`    [OK] ${key}`);
    } catch (e: any) {
        log(`    [ERR] ${key}: ${e.message}`);
    }
}

function parseTime(s: string) {
    const [t, p] = s.split(" ");
    let [h, m] = t.split(":").map(Number);
    if (p === "PM" && h < 12) h += 12;
    if (p === "AM" && h === 12) h = 0;
    return { h, m };
}

function getUniqueCourses(template: any) {
    const u: Record<string, any> = {};
    for (const [day, classes] of Object.entries(template)) {
        if (!Array.isArray(classes)) continue;
        for (const c of classes) {
            if (!c.courseCode) continue;
            if (!u[c.courseCode]) u[c.courseCode] = { name: c.courseName, days: new Set() };
            u[c.courseCode].days.add(day);
        }
    }
    return u;
}

function getPattern(days: Set<string>) {
    const o: Record<string, string> = { 'Sunday': 'S', 'Monday': 'M', 'Tuesday': 'T', 'Wednesday': 'W', 'Thursday': 'R', 'Friday': 'F', 'Saturday': 'A' };
    const s: Record<string, number> = { 'S': 0, 'M': 1, 'T': 2, 'W': 3, 'R': 4, 'F': 5, 'A': 6 };
    return Array.from(days).map(d => o[d]).filter(x => !!x).sort((a, b) => s[a] - s[b]).join("");
}

function parseTextDate(d: string) {
    const p = d.split(" ");
    if (p.length !== 3) return null;
    const months: Record<string, number> = { 'January': 0, 'February': 1, 'March': 2, 'April': 3, 'May': 4, 'June': 5, 'July': 6, 'August': 7, 'September': 8, 'October': 9, 'November': 10, 'December': 11 };
    return new Date(Date.UTC(parseInt(p[2]), months[p[1]], parseInt(p[0]), 4, 0, 0));
}
