import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import postgres from 'https://deno.land/x/postgresjs@v3.3.4/mod.js';

const SUPABASE_DB_URL = Deno.env.get('SUPABASE_DB_URL') ?? 'postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres';

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

    log('Alert Scheduler (V2) started');
    const sql = postgres(SUPABASE_DB_URL, { max: 1 });

    try {
        const activeSemList = await sql`SELECT current_semester_code as semester_code FROM active_semester LIMIT 1`;
        let semCode = 'spring_2026';
        if (!activeSemList || activeSemList.length === 0) {
            const fbSem = await sql`SELECT code as semester_code FROM semesters WHERE is_active = true LIMIT 1`;
            if (fbSem && fbSem.length > 0) semCode = fbSem[0].semester_code;
        } else {
            semCode = activeSemList[0].semester_code;
        }
        log(`Active Semester: ${semCode}`);

          // Cleanup old dispatched notifications (older than 30 days) to save storage
          try {
              const res = await sql`DELETE FROM notifications WHERE is_dispatched = true AND trigger_at < NOW() - INTERVAL '30 days'`;
              log(`Cleared old notifications`);
          } catch(e: any) {
              log(`Cleanup failed: ${e.message}`);
          }


        const profiles = await sql`SELECT id FROM profiles`;
          log(`Found ${profiles.length} profiles to process`);
          const now = new Date();
        const offsetDay = 1; 
        const dhakaTarget = new Date(now.getTime() + (6 * 60 * 60 * 1000) + (offsetDay * 24 * 60 * 60 * 1000));
        
        const daysMap: Record<number, string> = { 0: 'S', 1: 'M', 2: 'T', 3: 'W', 4: 'R', 5: 'F', 6: 'A' };
        const dbDayChar = daysMap[dhakaTarget.getUTCDay()];
        const dateStr = dhakaTarget.toISOString().split('T')[0];

        for (const profile of profiles) {
            const userId = profile.id;
            try {
                // Determine uncompleted tasks
                const tasks = await sql`
                    SELECT id, title, due_date, type, course_code FROM tasks 
                    WHERE user_id = ${userId} 
                    AND is_completed = false
                `;
                for (const task of tasks) {
                    const dueUTC = new Date(task.due_date);
                    const dueTimeMs = dueUTC.getTime();
                    
                    const tType = (task.type || '').toLowerCase();
                    const isMajor = tType.includes('quiz') || tType.includes('mid') || tType.includes('final');
                    
                    const cCodeStr = task.course_code ? ` for ${task.course_code}` : '';
                    const dispTitle = task.title || 'Task';
                    
                    const dhakaDue = new Date(dueUTC.getTime() + (6 * 60 * 60 * 1000));
                    const h = dhakaDue.getUTCHours();
                    const m = dhakaDue.getUTCMinutes();
                    const ampm = h >= 12 ? 'PM' : 'AM';
                    const h12 = h % 12 || 12;
                    const mStr = m.toString().padStart(2, '0');
                    const timeStr = `${h12}:${mStr} ${ampm}`;
                    
                    const daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                    const dateStrFormat = `${daysOfWeek[dhakaDue.getUTCDay()]}, ${months[dhakaDue.getUTCMonth()]} ${dhakaDue.getUTCDate()}`;

                    const baseBodyText = `You have ${dispTitle} scheduled for ${task.course_code || 'Unknown Course'} at ${timeStr} on ${dateStrFormat}`;

                    if (isMajor) {
                        await scheduleAlert(sql, userId, new Date(dueTimeMs - 3 * 24 * 60 * 60 * 1000),
                            `Upcoming: ${task.type || 'Assessment'}${cCodeStr}`,
                            `${baseBodyText}. (in 3 days)`,
                            'task_reminder', `t_3d:${task.id}`, log);
                    }

                    await scheduleAlert(sql, userId, new Date(dueTimeMs - 24 * 60 * 60 * 1000),
                        `Due Tomorrow${cCodeStr}`,
                        `${baseBodyText}. (Tomorrow)`,
                        'task_reminder', `t_1d:${task.id}`, log);

                    let dueMorningUTC = new Date(Date.UTC(
                        dhakaDue.getUTCFullYear(),
                        dhakaDue.getUTCMonth(),
                        dhakaDue.getUTCDate(),
                        2, 0, 0
                    ));

                    if (dueMorningUTC.getTime() >= dueTimeMs) {
                        dueMorningUTC = new Date(dueTimeMs - 2 * 60 * 60 * 1000);
                    }

                    await scheduleAlert(sql, userId, dueMorningUTC,
                        `Due Today${cCodeStr}`,
                        `${baseBodyText}.`,
                        'task_reminder', `t_0d:${task.id}`, log);
                }

                const c_tbl = sql('courses_' + semCode.toLowerCase().replace(/[\s_]/g, ''));

                const enrols = await sql`
                    SELECT e.course_code, c.schedule_data
                    FROM enrollments e
                    LEFT JOIN ${c_tbl} c ON e.section_id = c.id
                    WHERE e.user_id = ${userId} AND e.status = 'enrolled'
                `;

                if (!enrols || enrols.length === 0) continue;

                const ex = await sql`SELECT course_code FROM schedule_exceptions WHERE user_id = ${userId} AND date = ${dateStr} AND (type = 'cancel' OR type = 'holiday')`;
                const cancelledSet = new Set(ex.map(e => e.course_code));

                let todaysClasses: any[] = [];

                for(const enr of enrols) {
                    if (cancelledSet.has(enr.course_code)) continue;

                    const sched = enr.schedule_data;
                    if (!sched || !Array.isArray(sched)) continue;

                    for(const session of sched) {
                        if (session.day && session.day.includes(dbDayChar)) {
                            todaysClasses.push({
                                courseCode: enr.course_code,
                                startTime: session.startTime,
                                endTime: session.endTime,
                                venue: session.room || 'TBA'
                            });
                        }
                    }
                }

                if (todaysClasses.length === 0) continue;

                todaysClasses.sort((a, b) => {
                    const ta = parseTime(a.startTime);
                    const tb = parseTime(b.startTime);
                    return (ta.h * 60 + ta.m) - (tb.h * 60 + tb.m);
                });

                for (let i = 0; i < todaysClasses.length; i++) {
                    const c = todaysClasses[i];
                    const time = parseTime(c.startTime);
                    
                    const classStartUTC = new Date(Date.UTC(
                        dhakaTarget.getUTCFullYear(),
                        dhakaTarget.getUTCMonth(),
                        dhakaTarget.getUTCDate(),
                        time.h - 6, time.m, 0
                    ));

                    const bodyText = `You have a class of ${c.courseCode} at ${c.startTime} in ${c.venue}`;

                    if (i === 0) {
                        for (const m of [45, 30, 15, 5]) {
                            await scheduleAlert(sql, userId, new Date(classStartUTC.getTime() - m * 60000),
                                `Upcoming Class: ${c.courseCode}`, bodyText,
                                'reminder', `c_${m}m:${c.courseCode}:${dateStr}`, log);
                        }
                    } else {
                        const prev = todaysClasses[i - 1];
                        const prevEnd = parseTime(prev.endTime);
                        
                        const pEndMins = prevEnd.h * 60 + prevEnd.m;
                        const currStartMins = time.h * 60 + time.m;
                        const gap = currStartMins - pEndMins;

                        if (gap < 30) {
                            await scheduleAlert(sql, userId, new Date(classStartUTC.getTime() - 5 * 60000),
                                `Next Class: ${c.courseCode}`, bodyText,
                                'reminder', `c_5m:${c.courseCode}:${dateStr}`, log);
                        } else {
                            for (const m of [30, 15, 5]) {
                                await scheduleAlert(sql, userId, new Date(classStartUTC.getTime() - m * 60000),
                                    `Next Class: ${c.courseCode}`, bodyText,
                                    'reminder', `c_${m}m:${c.courseCode}:${dateStr}`, log);
                            }
                        }
                    }
                }
                
                log(`Scheduled logic for ${userId}: ${todaysClasses.length} classes, ${tasks.length} tasks.`);
            } catch (err: any) {
                log(`Error processing user ${userId}: ${err.message}`);
            }
        }

        await sql.end();
        return new Response(JSON.stringify({ message: 'Scheduling Complete', logs }), { status: 200, headers: { 'Content-Type': 'application/json' } });        
    } catch (err: any) {
        log(`Fatal Error: ${err.message}`);
        await sql.end();
        return new Response(JSON.stringify({ error: err.message, logs }), { status: 500, headers: { 'Content-Type': 'application/json' } });
    }
});

async function scheduleAlert(sql: any, userId: string, trigger: Date, title: string, body: string, type: string, key: string, log: Function) {
    if (trigger < new Date()) return;
    try {
        await sql`INSERT INTO notifications (user_id, trigger_at, title, body, type, is_dispatched, payload, alert_key)
                  VALUES (${userId}, ${trigger.toISOString()}, ${title}, ${body}, ${type}, false, ${JSON.stringify({})}, ${key})
                  ON CONFLICT (user_id, alert_key) DO UPDATE SET
                  trigger_at = EXCLUDED.trigger_at, title = EXCLUDED.title, body = EXCLUDED.body, is_dispatched = false`;
    } catch (e: any) {
        log(`    [ERR] ${key}: ${e.message}`);
    }
}

function parseTime(s: string) {
    if (!s) return { h: 0, m: 0 };
    const parts = s.split(' ');
    if(parts.length < 2) return {h: 0, m: 0};
    const t = parts[0];
    const p = parts[1];
    let h = parseInt(t.split(':')[0]);
    let m = parseInt(t.split(':')[1]);
    if (isNaN(h) || isNaN(m)) return {h: 0, m: 0};
    if (p === 'PM' && h < 12) h += 12;
    if (p === 'AM' && h === 12) h = 0;
    return { h, m };
}
