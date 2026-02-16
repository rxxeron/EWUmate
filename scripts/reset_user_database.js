const { createClient } = require('@supabase/supabase-js');

// Config from project
const PROJECT_REF = 'jwygjihrbwxhehijldiz';
const SUPABASE_URL = `https://${PROJECT_REF}.supabase.co`;
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false }
});

async function resetUserData() {
    console.log("🔥 Starting COMPLETE User Data Reset...");

    const userRelatedTables = [
        'fcm_tokens',
        'semester_progress',
        'user_schedules',
        'academic_data',
        'schedule_generations',
        'profiles'
    ];

    // 1. Delete rows from user-related tables
    for (const table of userRelatedTables) {
        console.log(`   🧹 Clearing table: ${table}...`);
        const { error } = await supabase.from(table).delete().neq('id', '00000000-0000-0000-0000-000000000000'); // Delete all
        // Note: For tables where the key isn't 'id' (like academic_data uses user_id),
        // we might need a different approach or just filter by something that matches everyone.
        // Actually, .delete() without filters might be blocked by Supabase, 
        // but .neq('id', 'xxx') usually works for any UUID.

        let deleteQuery = supabase.from(table).delete();
        if (table === 'academic_data' || table === 'semester_progress' || table === 'user_schedules' || table === 'fcm_tokens' || table === 'schedule_generations') {
            deleteQuery = deleteQuery.neq('user_id', '00000000-0000-0000-0000-000000000000');
        } else {
            deleteQuery = deleteQuery.neq('id', '00000000-0000-0000-0000-000000000000');
        }

        const { error: delErr } = await deleteQuery;
        if (delErr) {
            console.error(`      ❌ Error clearing ${table}: ${delErr.message}`);
        } else {
            console.log(`      ✅ Cleared ${table}.`);
        }
    }

    // 2. Delete all Auth Users
    console.log("\n👥 Deleting all Auth Users...");
    try {
        const { data: { users }, error: listError } = await supabase.auth.admin.listUsers();
        if (listError) throw listError;

        console.log(`   Found ${users.length} users.`);
        for (const user of users) {
            const { error: delError } = await supabase.auth.admin.deleteUser(user.id);
            if (delError) {
                console.error(`      ❌ Failed to delete ${user.email || user.id}: ${delError.message}`);
            } else {
                console.log(`      ✅ Deleted ${user.email || user.id}`);
            }
        }
    } catch (e) {
        console.error(`   ❌ Auth Deletion Error: ${e.message}`);
    }

    console.log("\n✨ DATABASE RESET COMPLETE.");
    console.log("   Reference data (courses, course_metadata, metadata) was KEPT.");
}

resetUserData();
