const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc";

async function listAll() {
    // 1. Fetch Auth
    const authRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users?per_page=1000`, {
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });
    const authData = await authRes.json();
    const authUsers = authData.users || [];

    // 2. Fetch Profiles
    const profRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles?select=*&limit=1000`, {
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });
    const profiles = await profRes.json();

    const profMap = {};
    profiles.forEach(p => profMap[p.id] = p);

    const authMap = {};
    authUsers.forEach(u => authMap[u.id] = u);

    console.log("=== COMPLETE USER LIST ===");
    
    console.log("\n--- [ACTIVE USERS (Auth + Profile)] ---");
    authUsers.forEach(u => {
        const p = profMap[u.id];
        if (p) {
            console.log(`- ${p.full_name || 'No Name'} | Email: ${u.email} | Student ID: ${p.student_id || 'N/A'} | UUID: ${u.id}`);
        }
    });

    console.log("\n--- [PENDING ONBOARDING (Auth only)] ---");
    authUsers.forEach(u => {
        if (!profMap[u.id]) {
            console.log(`- Email: ${u.email} | UUID: ${u.id} | Registered: ${new Date(u.created_at).toLocaleDateString()}`);
        }
    });

    console.log("\n--- [ORPHAN PROFILES (No Auth linked)] ---");
    profiles.forEach(p => {
        if (!authMap[p.id]) {
            console.log(`- ${p.full_name} | Student ID: ${p.student_id} | UUID: ${p.id}`);
        }
    });
}
listAll().catch(console.error);
