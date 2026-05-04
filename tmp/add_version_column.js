const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY";

async function runSQL() {
    const sql = `
    -- Add app_version column to profiles
    ALTER TABLE profiles 
    ADD COLUMN IF NOT EXISTS app_version TEXT;

    -- Update RPC to also handle version if we want, or just leave it for the direct update
    -- We already have the direct update in the repository, so we just need the column.
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
        console.log("Successfully added app_version column to profiles table.");
    } else {
        const err = await res.text();
        console.error("Failed to run SQL:", res.status, err);
    }
}

runSQL().catch(console.error);
