const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY";

async function check() {
    // 1. Get profile
    const pRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles?select=id,full_name&student_id=eq.2025-2-60-089`, {
        headers: {
            "apikey": SUPABASE_KEY,
            "Authorization": `Bearer ${SUPABASE_KEY}`
        }
    });
    const profiles = await pRes.json();
    if (profiles.length === 0) {
        console.log("No profile found for 2025-2-60-089");
        return;
    }
    const userId = profiles[0].id;

    // 2. Get history
    const res = await fetch(`${SUPABASE_URL}/rest/v1/completed_courses?user_id=eq.${userId}`, {
        headers: {
            "apikey": SUPABASE_KEY,
            "Authorization": `Bearer ${SUPABASE_KEY}`
        }
    });
    const data = await res.json();
    console.log(data);
}
check().catch(console.error);
