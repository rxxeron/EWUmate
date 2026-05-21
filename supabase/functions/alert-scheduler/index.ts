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
        // 1. Fetch Active Semester Config for both tracks
        const activeSemList = await sql`SELECT track, current_semester_code, classes_start_date, classes_end_date FROM active_semester`;
        if (!activeSemList || activeSemList.length === 0) {
            log('No active semesters found in active_semester table.');
            return new Response(JSON.stringify({ message: 'No active semesters', logs }), { status: 200, headers: { 'Content-Type': 'application/json' } });
        }
        
        const semMap = new Map();
        activeSemList.forEach(s => {
            semMap.set(s.track, {
                code: s.current_semester_code,
                startDate: s.classes_start_date ? new Date(s.classes_start_date) : null,
                endDate: s.classes_end_date ? new Date(s.classes_end_date) : null
            });
        });

        // Use tri_semester as fallback for table name resolution if needed
        const defaultSemCode = semMap.get('tri_semester')?.code || 'spring2026';
        log(`Active Semesters: ${JSON.stringify(Object.fromEntries(semMap))}`);

        // 2. Cleanup old dispatched notifications (older than 30 days)
        try {
            await sql`DELETE FROM notifications WHERE is_dispatched = true AND trigger_at < NOW() - INTERVAL '30 days'`;
            log(`Cleared old dispatched notifications`);
        } catch(e: any) {
            log(`Cleanup failed: ${e.message}`);
        }

        const profiles = await sql`SELECT id FROM profiles`;
        log(`Found ${profiles.length} profiles to process`);
        const now = new Date();
        const daysMap: Record<number, string> = { 0: 'S', 1: 'M', 2: 'T', 3: 'W', 4: 'R', 5: 'F', 6: 'A' };
        const offsetDays = [0, 1]; // Process Today and Tomorrow

        for (const profile of profiles) {
            const userId = profile.id;
            try {
                // --- Task Reminders ---
                const tasks = await sql`
                    SELECT id, title, due_date, type, course_code FROM tasks 
                    WHERE user_id = ${userId} AND is_completed = false
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
                            `${baseBodyText}. (in 3 days)`, 'task_reminder', `t_3d:${task.id}`, log);
                    }

                    await scheduleAlert(sql, userId, new Date(dueTimeMs - 24 * 60 * 60 * 1000),
                        `Due Tomorrow${cCodeStr}`, `${baseBodyText}. (Tomorrow)`, 'task_reminder', `t_1d:${task.id}`, log);

                    let dueMorningUTC = new Date(Date.UTC(dhakaDue.getUTCFullYear(), dhakaDue.getUTCMonth(), dhakaDue.getUTCDate(), 2, 0, 0));
                    if (dueMorningUTC.getTime() >= dueTimeMs) dueMorningUTC = new Date(dueTimeMs - 2 * 60 * 60 * 1000);

                    await scheduleAlert(sql, userId, dueMorningUTC, `Due Today${cCodeStr}`, `${baseBodyText}.`, 'task_reminder', `t_0d:${task.id}`, log);
                }

                // --- Class Reminders ---
                // Cleanup pending future class reminders for this user before rescheduling
                await sql`DELETE FROM notifications WHERE user_id = ${userId} AND is_dispatched = false AND type = 'reminder' AND trigger_at >= NOW()`;

                // 1. Get user track
                const [userMeta] = await sql`SELECT track FROM profiles WHERE id = ${userId} LIMIT 1`;
                const userTrack = userMeta?.track || 'tri_semester';
                const trackInfo = semMap.get(userTrack);

                if (trackInfo && trackInfo.code) {
                    const semesterCode = trackInfo.code;
                    
                    // 2. Fetch Weekly Grid Cache
                    const [state] = await sql`
                        SELECT weekly_grid_cache 
                        FROM user_semester_states 
                        WHERE user_id = ${userId} AND semester_code = ${semesterCode}
                        LIMIT 1
                    `;

                    if (state?.weekly_grid_cache) {
                        const grid = state.weekly_grid_cache;
                        const fullDayNames: Record<number, string> = { 0: 'Sunday', 1: 'Monday', 2: 'Tuesday', 3: 'Wednesday', 4: 'Thursday', 5: 'Friday', 6: 'Saturday' };

                        for (const offsetDay of offsetDays) {
                            const dhakaTarget = new Date(now.getTime() + (6 * 60 * 60 * 1000) + (offsetDay * 24 * 60 * 60 * 1000));
                            const dayName = fullDayNames[dhakaTarget.getUTCDay()];
                            const dateStr = dhakaTarget.toISOString().split('T')[0];
                            
                            // Verify Date safety (Start & End)
                            const targetDateOnly = new Date(dhakaTarget.getUTCFullYear(), dhakaTarget.getUTCMonth(), dhakaTarget.getUTCDate());
                            
                            if (trackInfo.startDate) {
                                const startDateOnly = new Date(trackInfo.startDate.getUTCFullYear(), trackInfo.startDate.getUTCMonth(), trackInfo.startDate.getUTCDate());
                                if (targetDateOnly < startDateOnly) continue;
                            }

                            if (trackInfo.endDate) {
                                const endDateOnly = new Date(trackInfo.endDate.getUTCFullYear(), trackInfo.endDate.getUTCMonth(), trackInfo.endDate.getUTCDate());
                                if (targetDateOnly > endDateOnly) continue;
                            }

                            const dayClasses = grid[dayName] || [];
                            if (dayClasses.length === 0) continue;

                            // Sort by time first
                            dayClasses.sort((a: any, b: any) => {
                                const ta = parseTime(a.startTime);
                                const tb = parseTime(b.startTime);
                                return (ta.h * 60 + ta.m) - (tb.h * 60 + tb.m);
                            });

                            for (let i = 0; i < dayClasses.length; i++) {
                                const c = dayClasses[i];
                                
                                // Determine course-level track
                                const cCode = (c.courseCode || '').toUpperCase();
                                const isProfessional = cCode.startsWith('PHRM') || cCode.startsWith('LAW') || cCode.startsWith('LLB');
                                const courseTrack = isProfessional ? 'bi_semester' : 'tri_semester';
                                const cTrackInfo = semMap.get(courseTrack);

                                // Verify course-level Date safety (Start & End)
                                if (cTrackInfo) {
                                    const targetDateOnly = new Date(dhakaTarget.getUTCFullYear(), dhakaTarget.getUTCMonth(), dhakaTarget.getUTCDate());
                                    
                                    if (cTrackInfo.startDate) {
                                        const startDateOnly = new Date(cTrackInfo.startDate.getUTCFullYear(), cTrackInfo.startDate.getUTCMonth(), cTrackInfo.startDate.getUTCDate());
                                        if (targetDateOnly < startDateOnly) continue;
                                    }

                                    if (cTrackInfo.endDate) {
                                        const endDateOnly = new Date(cTrackInfo.endDate.getUTCFullYear(), cTrackInfo.endDate.getUTCMonth(), cTrackInfo.endDate.getUTCDate());
                                        if (targetDateOnly > endDateOnly) continue;
                                    }
                                }

                                const time = parseTime(c.startTime);
                                const classStartUTC = new Date(Date.UTC(dhakaTarget.getUTCFullYear(), dhakaTarget.getUTCMonth(), dhakaTarget.getUTCDate(), time.h - 6, time.m, 0));
                                const bodyText = `You have a class of ${c.courseCode} at ${c.startTime} in ${c.room || c.venue || 'TBA'}`;

                                if (i === 0) {
                                    // Primary reminders for first class
                                    for (const m of [45, 30, 15, 5]) {
                                        await scheduleAlert(sql, userId, new Date(classStartUTC.getTime() - m * 60000), `Upcoming Class: ${c.courseCode}`, bodyText, 'reminder', `c_${m}m:${c.courseCode}:${dateStr}`, log);
                                    }
                                } else {
                                    // Verify gap with previous class in the original sorted list (before skips)
                                    // Actually, we should find the previous VALID class that wasn't skipped.
                                    // For simplicity, we keep the gap logic relative to the original sequence or just use standard intervals.
                                    const mList = [30, 15, 5];
                                    for (const m of mList) {
                                        await scheduleAlert(sql, userId, new Date(classStartUTC.getTime() - m * 60000), `Next Class: ${c.courseCode}`, bodyText, 'reminder', `c_${m}m:${c.courseCode}:${dateStr}`, log);
                                    }
                                }
                            }
                            log(`  [Scheduled Cache] ${userId} - ${dateStr}: ${dayClasses.length} courses processed`);
                        }
                    }
                }
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

function normalizeSem(s: string | null | undefined): string {
    if (!s) return '';
    return s.toLowerCase().replace(/[\s_]/g, '');
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
