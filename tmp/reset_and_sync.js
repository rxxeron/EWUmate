const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc";
const USER_ID = "4efd4ebc-a70b-404c-9934-0db39fec8f99";

function normalizeSem(sem) {
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

async function runReset() {
    console.log("--- Starting TOTAL RESET & SYNC ---");

    // 1. Fetch Metadata
    console.log("Fetching course metadata...");
    const metaRes = await fetch(`${SUPABASE_URL}/rest/v1/course_metadata?select=code,credit_val`, {
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });
    const metadata = await metaRes.json();
    const creditMap = new Map();
    metadata.forEach(m => creditMap.set(normalizeCourse(m.code), m.credit_val));

    // 2. Clear summaries
    console.log(`Clearing semester_summaries for ${USER_ID}...`);
    await fetch(`${SUPABASE_URL}/rest/v1/semester_summaries?user_id=eq.${USER_ID}`, {
        method: 'DELETE',
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });

    // 3. Process completed_courses
    console.log(`Processing completed_courses for ${USER_ID}...`);
    const coursesRes = await fetch(`${SUPABASE_URL}/rest/v1/completed_courses?user_id=eq.${USER_ID}&select=*`, {
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });
    const courses = await coursesRes.json();
    
    const courseGroup = new Map(); // key -> list of rows
    for (const c of courses) {
        const key = `${normalizeCourse(c.course_code)}|${normalizeSem(c.semester_code)}`;
        if (!courseGroup.has(key)) courseGroup.set(key, []);
        courseGroup.get(key).push(c);
    }

    console.log(`Deduplicating and updating ${courseGroup.size} unique course-semester pairs...`);
    for (const [key, rows] of courseGroup) {
        const [toKeep, ...toDelete] = rows;
        const normCourse = normalizeCourse(toKeep.course_code);
        const normSem = normalizeSem(toKeep.semester_code);
        const correctCredits = creditMap.get(normCourse) || toKeep.credit_val || 3.0; // Fallback to current or 3.0

        // Update the one we keep
        await fetch(`${SUPABASE_URL}/rest/v1/completed_courses?id=eq.${toKeep.id}`, {
            method: 'PATCH',
            headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}`, "Content-Type": "application/json" },
            body: JSON.stringify({ 
                course_code: normCourse, 
                semester_code: normSem,
                credit_val: correctCredits
            })
        });

        // Delete duplicates
        for (const d of toDelete) {
            await fetch(`${SUPABASE_URL}/rest/v1/completed_courses?id=eq.${d.id}`, {
                method: 'DELETE',
                headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
            });
        }
    }

    // 4. Trigger Sync
    console.log("Triggering final sync...");
    await fetch(`${SUPABASE_URL}/functions/v1/sync-academic-stats`, {
        method: 'POST',
        headers: { "Authorization": `Bearer ${SUPABASE_KEY}`, "Content-Type": "application/json" },
        body: JSON.stringify({ user_id: USER_ID })
    });

    console.log("--- RESET & SYNC COMPLETE ---");
}

runReset().catch(console.error);
