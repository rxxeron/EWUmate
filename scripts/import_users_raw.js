const fs = require('fs');

// ----------------------------------------------------
// ⚠️ CREDENTIALS ⚠️
// ----------------------------------------------------
const PROJECT_REF = 'jwygjihrbwxhehijldiz'; // Taken from supabase URL
const SUPABASE_URL = `https://${PROJECT_REF}.supabase.co`;
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';

// Firebase SCRYPT Config (from user)
const HASH_CONFIG = {
    algorithm: 'SCRYPT', // Must be uppercase for API enum usually
    base64_signer_key: 'YXZbw+9CBo+a9TWnA9BFBAmefSZaCY4tX1/i6PARrK+27RonffUwvsZI6CPxaOFLSlnFTXO41h7Ezat23Ktq7Q==',
    base64_salt_separator: 'Bw==',
    rounds: 8,
    mem_cost: 14
};

async function importUsersRaw() {
    console.log("🚀 Starting Raw HTTP Import via GoTrue API...");

    // Load users
    const usersPath = './scripts/users_with_hashes.json';
    if (!fs.existsSync(usersPath)) {
        console.error("❌ users_with_hashes.json not found!");
        return;
    }

    const rawUsers = JSON.parse(fs.readFileSync(usersPath, 'utf8'));
    console.log(`Loaded ${rawUsers.length} users from file.`);

    // Map to API format
    // API expects:
    // {
    //   "users": [ { "id": "...", "email": "...", "password_hash": "...", "password_salt": "...", ... } ],
    //   "hash_config": { ... }
    // }

    const usersPayload = rawUsers.map(u => ({
        id: u.id,
        email: u.email,
        password_hash: u.password_hash,
        password_salt: u.password_salt,
        email_confirm: u.email_verified,
        phone: u.phone,
        phone_confirm: !!u.phone, // approximate
        user_metadata: u.user_metadata,
        app_metadata: u.app_metadata,
        created_at: u.created_at,
        updated_at: u.updated_at
    }));

    const url = `${SUPABASE_URL}/auth/v1/admin/users`;

    try {
        const resp = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
                'apikey': SUPABASE_SERVICE_ROLE_KEY
            },
            body: JSON.stringify({
                users: usersPayload,
                hash_config: HASH_CONFIG
            })
        });

        if (!resp.ok) {
            const errText = await resp.text();
            console.error(`❌ HTTP Error ${resp.status}:`, errText);
        } else {
            const result = await resp.json();
            console.log("✅ Import Success!");
            console.log(`   Imported: ${result.length || 'Unknown count'} users`);
        }
    } catch (e) {
        console.error("❌ Network Error:", e);
    }
}

importUsersRaw();
