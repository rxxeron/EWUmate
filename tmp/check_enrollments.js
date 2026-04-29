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
    if (profiles.length === 0) {
        console.log("No profile found for 2025-2-50-009");
        return;
    }
    const userId = profiles[0].id;
    console.log(`Found user: ${profiles[0].full_name} (${userId})`);

    // 2. Get enrollments
    const res = await fetch(`${SUPABASE_URL}/rest/v1/enrollments?user_id=eq.${userId}`, {
        headers: {
            "apikey": SUPABASE_KEY,
            "Authorization": `Bearer ${SUPABASE_KEY}`
        }
    });
    const data = await res.json();
    console.log(data);
}
check().catch(console.error);
