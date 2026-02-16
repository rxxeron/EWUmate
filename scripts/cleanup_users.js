const { createClient } = require('@supabase/supabase-js');

// ----------------------------------------------------
// ⚠️ CREDENTIALS ⚠️
// ----------------------------------------------------
const SUPABASE_URL = 'https://jwygjihrbwxhehijldiz.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';

async function cleanupUsers() {
    console.log("🧹 cleaning up existing users in Supabase...");

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
        auth: {
            autoRefreshToken: false,
            persistSession: false
        }
    });

    // Get all users
    const { data: { users }, error } = await supabase.auth.admin.listUsers();

    if (error) {
        console.error("❌ Error listing users:", error);
        return;
    }

    if (users.length === 0) {
        console.log("✅ No users found. Safe to import.");
        return;
    }

    console.log(`Found ${users.length} users to delete...`);

    for (const user of users) {
        const { error: delError } = await supabase.auth.admin.deleteUser(user.id);
        if (delError) {
            console.error(`❌ Failed to delete ${user.email}:`, delError.message);
        } else {
            console.log(`✅ Deleted ${user.email}`);
        }
    }

    console.log("🎉 Cleanup complete.");
}

cleanupUsers();
