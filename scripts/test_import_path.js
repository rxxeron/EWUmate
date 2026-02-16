const fs = require('fs');
const PROJECT_REF = 'jwygjihrbwxhehijldiz';
const SUPABASE_URL = `https://${PROJECT_REF}.supabase.co`;
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';

async function testPath() {
    const paths = [
        '/auth/v1/admin/users/import',
        '/auth/v1/admin/import',
        '/auth/v1/import/users',
        '/auth/v1/users/import'
    ];

    // Minimal valid payload
    const payload = {
        users: [{
            id: 'test-user-import',
            email: 'test-import@example.com',
            password_hash: 'hash',
            password_salt: 'salt'
        }],
        hash_config: { algorithm: 'scrypt', rounds: 8, mem_cost: 14, base64_signer_key: 'key', base64_salt_separator: 'sep' }
    };

    for (const p of paths) {
        const url = `${SUPABASE_URL}${p}`;
        console.log(`Testing ${url}...`);
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
            console.log(`  -> Status: ${resp.status}`);
            if (resp.status !== 404) {
                console.log(`  ✅ MATCH! Text:`, await resp.text());
                return;
            }
        } catch (e) { console.error(e.message); }
    }
    console.log("No valid import endpoint found.");
}

testPath();
