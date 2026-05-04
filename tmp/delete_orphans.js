const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc";

async function cleanOrphans() {
    const authRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users?per_page=1000`, {
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });
    const authData = await authRes.json();
    const authUsers = authData.users || [];

    const profRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles?select=id&limit=1000`, {
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });
    const profiles = await profRes.json();
    const profIds = new Set(profiles.map(p => p.id));

    const orphans = authUsers.filter(u => !profIds.has(u.id));
    console.log(`Found ${orphans.length} orphan users to remove.`);

    for (const u of orphans) {
        console.log(`Deleting user: ${u.email} (${u.id})...`);
        const delRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${u.id}`, {
            method: 'DELETE',
            headers: { 
                "apikey": SUPABASE_KEY, 
                "Authorization": `Bearer ${SUPABASE_KEY}` 
            }
        });
        if (delRes.ok) {
            console.log(`Successfully deleted ${u.email}`);
        } else {
            console.log(`Failed to delete ${u.id}: ${delRes.statusText}`);
        }
    }
}
cleanOrphans().catch(console.error);
