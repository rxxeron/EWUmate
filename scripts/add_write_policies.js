const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://jwygjihrbwxhehijldiz.supabase.co';
const SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';

const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

async function addWritePolicies() {
    console.log("Adding INSERT/UPDATE RLS policies for user-owned tables...\n");

    const policies = [
        // Profiles
        `CREATE POLICY IF NOT EXISTS "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id)`,
        `CREATE POLICY IF NOT EXISTS "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id)`,

        // Academic Data
        `CREATE POLICY IF NOT EXISTS "Users can insert own academic" ON public.academic_data FOR INSERT WITH CHECK (auth.uid() = user_id)`,
        `CREATE POLICY IF NOT EXISTS "Users can update own academic" ON public.academic_data FOR UPDATE USING (auth.uid() = user_id)`,

        // Semester Progress
        `CREATE POLICY IF NOT EXISTS "Users can insert own progress" ON public.semester_progress FOR INSERT WITH CHECK (auth.uid() = user_id)`,
        `CREATE POLICY IF NOT EXISTS "Users can update own progress" ON public.semester_progress FOR UPDATE USING (auth.uid() = user_id)`,

        // Schedule Generations
        `CREATE POLICY IF NOT EXISTS "Users can view own generations" ON public.schedule_generations FOR SELECT USING (auth.uid() = user_id)`,
        `CREATE POLICY IF NOT EXISTS "Users can insert own generations" ON public.schedule_generations FOR INSERT WITH CHECK (auth.uid() = user_id)`,
        `CREATE POLICY IF NOT EXISTS "Users can delete own generations" ON public.schedule_generations FOR DELETE USING (auth.uid() = user_id)`,

        // User Schedules
        `CREATE POLICY IF NOT EXISTS "Users can insert own schedules" ON public.user_schedules FOR INSERT WITH CHECK (auth.uid() = user_id)`,
        `CREATE POLICY IF NOT EXISTS "Users can update own schedules" ON public.user_schedules FOR UPDATE USING (auth.uid() = user_id)`,
    ];

    for (const sql of policies) {
        const policyName = sql.match(/"([^"]+)"/)?.[1] || 'unknown';
        const { error } = await supabase.rpc('exec_sql', { sql_query: sql });
        if (error) {
            // Try direct approach if exec_sql doesn't exist
            console.log(`   ⚠️  RPC failed for "${policyName}": ${error.message}`);
        } else {
            console.log(`   ✅ ${policyName}`);
        }
    }

    console.log("\n✨ Done! Policies should now allow authenticated users to write to their own data.");
    console.log("\n⚠️  If RPC failed, run the SQL manually in Supabase Dashboard > SQL Editor.");
    console.log("   File: supabase/migrations/20260216210000_add_write_policies.sql");
}

addWritePolicies();
