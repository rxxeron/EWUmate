const fs = require('fs');
const { createClient } = require('@supabase/supabase-js');

// Config
const PROJECT_REF = 'jwygjihrbwxhehijldiz';
const SUPABASE_URL = `https://${PROJECT_REF}.supabase.co`;
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';

async function finalMigration() {
    console.log("🚀 Starting Final User Migration (with Metadata)...");

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
        auth: { autoRefreshToken: false, persistSession: false }
    });

    const usersPath = './scripts/users_with_hashes.json';
    if (!fs.existsSync(usersPath)) {
        console.error("❌ users_with_hashes.json not found!");
        return;
    }

    const users = JSON.parse(fs.readFileSync(usersPath, 'utf8'));
    console.log(`Loaded ${users.length} users.`);

    for (const u of users) {
        console.log(`Processing ${u.email}...`);

        try {
            // Attempt to create user with ALL metadata
            // Password is set to random/temp as we can't migrate hash without CLI
            const { data, error } = await supabase.auth.admin.createUser({
                email: u.email,
                email_confirm: u.email_verified,
                phone: u.phone,
                phone_confirm: !!u.phone,
                user_metadata: u.user_metadata,
                app_metadata: u.app_metadata,
                password: "temp-password-123", // They must reset this
            });

            if (error) {
                console.error(`   ❌ Failed: ${error.message}`);
            } else {
                console.log(`   ✅ Created (ID: ${data.user.id})`);
                // Send password reset email? Optional.
                // await supabase.auth.resetPasswordForEmail(u.email);
            }
        } catch (e) {
            console.error(`   ❌ Exception: ${e.message}`);
        }
    }

    console.log("\nMigration complete.");
    console.log("⚠️ Passwords could not be migrated due to CLI issues.");
    console.log("   Users must use 'Forgot Password' to set a new password.");
}

finalMigration();
