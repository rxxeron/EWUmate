const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

// ----------------------------------------------------
// ⚠️ CREDENTIALS ⚠️
// ----------------------------------------------------
const SUPABASE_URL = 'https://jwygjihrbwxhehijldiz.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';

// Firebase SCRYPT Config (from user)
const HASH_CONFIG = {
    algorithm: 'scrypt',
    key: 'YXZbw+9CBo+a9TWnA9BFBAmefSZaCY4tX1/i6PARrK+27RonffUwvsZI6CPxaOFLSlnFTXO41h7Ezat23Ktq7Q==',
    salt_separator: 'Bw==',
    rounds: 8,
    memory_cost: 14
};

async function importUsers() {
    console.log("🚀 Starting JS Import (bypassing CLI)...");

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
        auth: {
            autoRefreshToken: false,
            persistSession: false
        }
    });

    // Load users
    const usersPath = './scripts/users_with_hashes.json';
    if (!fs.existsSync(usersPath)) {
        console.error("❌ users_with_hashes.json not found!");
        return;
    }

    const users = JSON.parse(fs.readFileSync(usersPath, 'utf8'));
    console.log(`Loaded ${users.length} users from file.`);

    // Prepare for importUsers API
    // Note: key names must match what GoTrue expects.
    // JS Client usually maps these.
    const usersToImport = users.map(u => ({
        uid: u.id, // JS client often uses 'uid' or 'id', let's try 'id' first if 'uid' fails?
        // Actually Supabase Admin API usually takes 'id'
        id: u.id,
        email: u.email,
        password_hash: u.password_hash,
        password_salt: u.password_salt,
        email_confirm: u.email_verified,
        user_metadata: u.user_metadata,
        app_metadata: u.app_metadata
    }));

    // Try calling importUsers if it exists
    // If not, we will construct the fetch call manually
    if (supabase.auth.admin.importUsers) {
        console.log("Found native importUsers method. Using it...");
        /* 
           signature: importUsers(users: UserImport[], options?: { hash: PasswordHashConfig }) 
        */
        // Note: base64_signer_key in config might need to be 'key'
        // Let's rely on the keys I set in HASH_CONFIG

        const { data, error } = await supabase.auth.admin.importUsers(usersToImport, {
            hash: HASH_CONFIG
        });

        if (error) {
            console.error("❌ Import failed:", error);
        } else {
            console.log("✅ Import success!", data);
        }
    } else {
        console.log("⚠️ Native importUsers not found. Trying raw fetch...");
        // Implementation of raw fetch backup if needed
        // ...
        console.error("Please update @supabase/supabase-js to latest version.");
    }
}

importUsers();
