const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY";

async function check() {
    // 1. Get profile
    const pRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles?select=id,full_name&student_id=eq.2026-1-70-085`, {
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });
    const profiles = await pRes.json();
    if (profiles.length === 0) {
        console.log("No profile found");
        return;
    }
    const userId = profiles[0].id;
    console.log(`Found Afifa: ${userId}`);

    // 2. Get enrollments
    const enRes = await fetch(`${SUPABASE_URL}/rest/v1/enrollments?user_id=eq.${userId}`, {
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });
    const enrollments = await enRes.json();
    console.log("Enrollments:", enrollments);

    // 3. Get tasks
    const tRes = await fetch(`${SUPABASE_URL}/rest/v1/tasks?user_id=eq.${userId}`, {
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });
    const tasks = await tRes.json();
    console.log("Tasks:", tasks);
}
check().catch(console.error);
