const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY";

async function check() {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/profiles?select=full_name,student_id,track&track=eq.bi_semester`, {
        headers: {
            "apikey": SUPABASE_KEY,
            "Authorization": `Bearer ${SUPABASE_KEY}`
        }
    });
    const data = await res.json();
    console.log(`Found ${data.length} bi-semester students:`);
    console.log(data);
}
check().catch(console.error);
