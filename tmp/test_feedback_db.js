const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY";

async function checkPolicies() {
    const sql = `
    SELECT tablename, policyname, roles, cmd, qual, with_check
    FROM pg_policies
    WHERE tablename = 'feedbacks';
    `;

    const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_sql`, {
        method: 'POST',
        headers: {
            "apikey": SUPABASE_KEY,
            "Authorization": `Bearer ${SUPABASE_KEY}`,
            "Content-Type": "application/json"
        },
        body: JSON.stringify({ sql_query: sql })
    });
    
    // Since exec_sql returns void, we can't get results this way easily if it's defined as returns void.
    // Wait, the definition of exec_sql is RETURNS void.
    // I'll use a different approach to check if we can select from it.
}

async function testSelect() {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/feedbacks?select=*`, {
        headers: {
            "apikey": SUPABASE_KEY,
            "Authorization": `Bearer ${SUPABASE_KEY}`
        }
    });
    console.log("Select Status:", res.status);
    const data = await res.json();
    console.log("Data count:", data.length);
    if (data.length > 0) {
        console.log("Sample:", data[0]);
    }
}

testSelect().catch(console.error);
