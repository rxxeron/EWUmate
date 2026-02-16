const { createClient } = require('@supabase/supabase-js');

const PROJECT_REF = 'jwygjihrbwxhehijldiz';
const SUPABASE_URL = `https://${PROJECT_REF}.supabase.co`;
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function debugUser() {
    console.log("🛠️ Testing user creation with custom ID...");
    const testId = 'TEST_UID_12345';

    // 1. Delete if exist
    await supabase.auth.admin.deleteUser(testId).catch(() => { });

    // 2. Create with custom ID
    const { data, error } = await supabase.auth.admin.createUser({
        id: testId,
        email: 'test@example.com',
        password: 'password123',
        email_confirm: true
    });

    if (error) {
        console.error("❌ Auth Error:", error.message);
    } else {
        console.log("✅ Auth Success! Created ID:", data.user.id);

        // 3. Try profile insert
        const { error: pError } = await supabase.from('profiles').upsert({
            id: testId,
            full_name: 'Test Name'
        });

        if (pError) console.error("❌ Profile Error:", pError.message);
        else console.log("✅ Profile Success!");
    }
}

debugUser();
