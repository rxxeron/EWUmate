const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY";

async function compare() {
    // 1. Fetch ALL Auth Users (Iterate if necessary, but assume < 1000 for now)
    const authRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users?per_page=1000`, {
        headers: {
            "apikey": SUPABASE_KEY,
            "Authorization": `Bearer ${SUPABASE_KEY}`
        }
    });
    const authData = await authRes.json();
    const authUsers = authData.users || [];
    
    // 2. Fetch ALL Profile Rows
    const profRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles?select=id,full_name,student_id&limit=1000`, {
        headers: {
            "apikey": SUPABASE_KEY,
            "Authorization": `Bearer ${SUPABASE_KEY}`
        }
    });
    const profiles = await profRes.json();

    const authIds = new Set(authUsers.map(u => u.id));
    const profIds = new Set(profiles.map(p => p.id));
    
    const orphanAuth = authUsers.filter(u => !profIds.has(u.id));
    const orphanProfiles = profiles.filter(p => !authIds.has(p.id));

    console.log("=== RESULTS ===");
    console.log(`Total Auth Users: ${authUsers.length}`);
    console.log(`Total Profiles: ${profiles.length}`);
    console.log(`Orphan Auth Users (No Profile): ${orphanAuth.length}`);
    console.log(`Orphan Profiles (No Auth record): ${orphanProfiles.length}`);

    console.log("\n--- ORPHAN AUTH USERS ---");
    orphanAuth.forEach(u => console.log(`- ${u.email} (${u.id})`));

    console.log("\n--- ORPHAN PROFILES ---");
    orphanProfiles.forEach(p => console.log(`- ${p.full_name || 'No Name'} | ID: ${p.student_id || 'No ID'} (${p.id})`));
}
compare().catch(console.error);
