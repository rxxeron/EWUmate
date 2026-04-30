const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY";

async function fixRLS() {
    const sql = `
    -- Enable RLS
    ALTER TABLE feedbacks ENABLE ROW LEVEL SECURITY;

    -- Drop existing policies if any to start fresh
    DROP POLICY IF EXISTS "Users can insert their own feedback" ON feedbacks;
    DROP POLICY IF EXISTS "Users can view their own feedback" ON feedbacks;
    DROP POLICY IF EXISTS "Admins can view all feedback" ON feedbacks;
    DROP POLICY IF EXISTS "Admins can update feedback status" ON feedbacks;

    -- 1. Users can insert feedback
    CREATE POLICY "Users can insert their own feedback" 
    ON feedbacks FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

    -- 2. Users can view their own feedback (for history tab in app)
    CREATE POLICY "Users can view their own feedback" 
    ON feedbacks FOR SELECT 
    USING (auth.uid() = user_id);

    -- 3. Service role (Admin) can do everything - this is default usually, but let's be explicit if needed for public.exec_sql users
    -- Actually service_role bypasses RLS.
    
    -- Grant permissions
    GRANT ALL ON feedbacks TO authenticated, service_role;
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
        console.log("Successfully fixed RLS for feedbacks table.");
    } else {
        const err = await res.text();
        console.error("Failed to fix RLS:", res.status, err);
    }
}

fixRLS().catch(console.error);
