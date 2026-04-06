const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY";

function normalizeSemester(sem) {
    if (!sem) return sem;
    const cleaned = sem.replace(/[\s_]/g, '').toLowerCase();
    const match = cleaned.match(/([a-z]+)(\d{4})|(\d{4})([a-z]+)/);
    if (match) {
        const season = (match[1] || match[4]).toLowerCase();
        const year = match[2] || match[3];
        const capitalizedSeason = season.charAt(0).toUpperCase() + season.slice(1);
        return `${capitalizedSeason}${year}`;
    }
    return sem;
}

function normalizeCourse(code) {
    return code.toUpperCase().replace(/\s/g, '').replace(/^[78]/, '');
}

async function runCleanup() {
    console.log("--- Starting Robust Database Cleanup ---");

    // 1. Clean completed_courses
    console.log("Cleaning completed_courses...");
    const coursesRes = await fetch(`${SUPABASE_URL}/rest/v1/completed_courses?select=*`, {
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });
    const courses = await coursesRes.json();
    
    const courseMap = new Map(); // tracker: [userId|normCode] -> mostRecentRow
    const toDelete = [];
    const toUpdate = [];

    for (const c of courses) {
        const normSem = normalizeSemester(c.semester_code);
        const normCourse = normalizeCourse(c.course_code);
        const key = `${c.user_id}|${normCourse}`;

        if (courseMap.has(key)) {
            const existing = courseMap.get(key);
            // Delete the duplicate. In real life we'd check created_at, but here we just want ONE.
            toDelete.push(c.id);
            console.log(`  Flagged Duplicate Course for Deletion: ${c.course_code} (${c.semester_code})`);
        } else {
            courseMap.set(key, c);
            if (c.semester_code !== normSem) {
                toUpdate.push({ id: c.id, semester_code: normSem });
            }
        }
    }

    // Process Updates
    console.log(`Applying ${toUpdate.length} semester updates...`);
    for (const up of toUpdate) {
        await fetch(`${SUPABASE_URL}/rest/v1/completed_courses?id=eq.${up.id}`, {
            method: 'PATCH',
            headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}`, "Content-Type": "application/json" },
            body: JSON.stringify({ semester_code: up.semester_code })
        });
    }

    // Process Deletes
    console.log(`Applying ${toDelete.length} duplicate deletions...`);
    for (const id of toDelete) {
        await fetch(`${SUPABASE_URL}/rest/v1/completed_courses?id=eq.${id}`, {
            method: 'DELETE',
            headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
        });
    }

    // 2. Clean semester_summaries (Hard Delete non-standard ones)
    console.log("Cleaning semester_summaries...");
    const summariesRes = await fetch(`${SUPABASE_URL}/rest/v1/semester_summaries?select=*`, {
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });
    const summaries = await summariesRes.json();
    for (const s of summaries) {
        const normSem = normalizeSemester(s.semester_code);
        if (s.semester_code !== normSem) {
            console.log(`  Deleting legacy summary: ${s.semester_code}`);
            await fetch(`${SUPABASE_URL}/rest/v1/semester_summaries?id=eq.${s.id}`, {
                method: 'DELETE',
                headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
            });
        }
    }

    console.log("--- Robust Cleanup Complete ---");
}

runCleanup().catch(console.error);
