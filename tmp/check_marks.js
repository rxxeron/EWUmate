const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY";

async function check() {
    // 1. Get profile
    const pRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles?select=id,full_name&student_id=eq.2025-2-50-009`, {
        headers: {
            "apikey": SUPABASE_KEY,
            "Authorization": `Bearer ${SUPABASE_KEY}`
        }
    });
    const profiles = await pRes.json();
    const userId = profiles[0].id;

    // 2. Get marks
    const res = await fetch(`${SUPABASE_URL}/rest/v1/semester_course_marks?user_id=eq.${userId}`, {
        headers: {
            "apikey": SUPABASE_KEY,
            "Authorization": `Bearer ${SUPABASE_KEY}`
        }
    });
    const data = await res.json();
    console.log(data);
}
check().catch(console.error);
