const fs = require('fs');
const PROJECT_REF = 'jwygjihrbwxhehijldiz';
const SUPABASE_URL = `https://${PROJECT_REF}.supabase.co`;
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';

async function importSingleUserTest() {
    console.log("🚀 Testing Single User Import with Hash...");

    const usersPath = './scripts/users_with_hashes.json';
    const rawUsers = JSON.parse(fs.readFileSync(usersPath, 'utf8'));
    const u = rawUsers[0]; // Take first user

    // Payload for Single User Creation
    // Note: We are trying to set password_hash directly.
    const payload = {
        id: u.id,
        email: u.email,
        password: "temp-password-123", // Fallback? No, we want hash.
        // Trying to set hash fields (might be ignored or rejected)
        password_hash: u.password_hash,
        password_salt: u.password_salt, // GoTrue usually needs this if hash is present
        email_confirm: u.email_verified,
        user_metadata: u.user_metadata,
        app_metadata: u.app_metadata
    };

    // Clean up undefined
    // ...

    const url = `${SUPABASE_URL}/auth/v1/admin/users`;

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

        const text = await resp.text();
        console.log(`Status: ${resp.status}`);
        console.log(`Response: ${text}`);

    } catch (e) {
        console.error("❌ Error:", e);
    }
}

importSingleUserTest();
