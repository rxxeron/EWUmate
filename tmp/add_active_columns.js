const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY";

async function runSQL() {
    const sql = `
    ALTER TABLE profiles 
    ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMP WITH TIME ZONE DEFAULT now();
    ALTER TABLE profiles 
    ADD COLUMN IF NOT EXISTS app_open_count INTEGER DEFAULT 0;
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
    
    if (res.ok) {
        console.log("Successfully added columns to profiles table.");
    } else {
        const err = await res.text();
        console.error("Failed to run SQL:", res.status, err);
    }
}

runSQL().catch(console.error);
