const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc";

async function runSQL() {
    const sql = `
    CREATE OR REPLACE FUNCTION increment_app_open_count(p_user_id uuid)
    RETURNS void AS $$
    BEGIN
      UPDATE profiles
      SET app_open_count = app_open_count + 1,
          last_active_at = now()
      WHERE id = p_user_id;
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER;
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
        console.log("Successfully created increment_app_open_count function.");
    } else {
        const err = await res.text();
        console.error("Failed to run SQL:", res.status, err);
    }
}

runSQL().catch(console.error);
