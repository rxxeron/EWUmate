const fs = require('fs');

// ----------------------------------------------------
// ⚠️ CREDENTIALS ⚠️
// ----------------------------------------------------
const PROJECT_REF = 'jwygjihrbwxhehijldiz';
const SUPABASE_URL = `https://${PROJECT_REF}.supabase.co`;
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';

async function importUsersOneByOne() {
    console.log("🚀 Starting Sequential User Import (Preserving Passwords)...");

    // Load users
    const usersPath = './scripts/users_with_hashes.json';
    if (!fs.existsSync(usersPath)) {
        console.error("❌ users_with_hashes.json not found!");
        return;
    }

    const rawUsers = JSON.parse(fs.readFileSync(usersPath, 'utf8'));
    console.log(`Loaded ${rawUsers.length} users to import.`);

    const url = `${SUPABASE_URL}/auth/v1/admin/users`;
    let successCount = 0;

    for (const u of rawUsers) {
        // Build payload for single user creation
        const payload = {
            id: u.id,
            email: u.email,
            email_confirm: u.email_verified,
            password_hash: u.password_hash,
            // Note: scrypt might need salt? Or maybe it's embedded in hash string?
            // Firebase provides password_salt separately.
            // GoTrue usually expects "password_hash" string.
            // BUT, we provided hash config (scrypt params) to the CLI import.
            // Here, we can't easily set global hash config via this endpoint usually...
            // Wait, if I set password_hash string, how does it know the salt?
            // GoTrue might rely on the FORMAT of the hash string (e.g. $scrypt$...).
            // Firebase hashes are raw base64 usually.
            // Let's try sending password_salt too if accepted.
            password_salt: u.password_salt,

            user_metadata: u.user_metadata,
            app_metadata: u.app_metadata
        };

        // Clean undefined
        if (!payload.password_salt) delete payload.password_salt;

        try {
            const resp = await fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
                    'apikey': SUPABASE_SERVICE_ROLE_KEY
                },
                body: JSON.stringify(payload)
            });

            if (!resp.ok) {
                const errText = await resp.text();
                console.error(`❌ Failed ${u.email}: ${errText}`);
            } else {
                const result = await resp.json();
                console.log(`✅ Imported: ${u.email} (ID: ${result.id})`);
                successCount++;
            }
        } catch (e) {
            console.error(`❌ Network Error for ${u.email}:`, e.message);
        }

        // Small delay to be nice
        await new Promise(r => setTimeout(r, 200));
    }

    console.log(`\n🎉 Finished! Imported ${successCount}/${rawUsers.length} users.`);
}

importUsersOneByOne();
