const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY";

async function testInsert() {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/feedbacks`, {
        method: 'POST',
        headers: {
            "apikey": SUPABASE_KEY,
            "Authorization": `Bearer ${SUPABASE_KEY}`,
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        },
        body: JSON.stringify({
            message: "Test feedback from script",
            user_id: '374a09cd-c366-4eea-89cc-dbda99154c3e' // Using the existing user_id from sample
        })
    });
    console.log("Insert Status:", res.status);
    const data = await res.json();
    console.log("Inserted Data:", data);
}

testInsert().catch(console.error);
