const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc";

async function globalSync() {
    console.log("--- Starting Global Academic Sync ---");

    // 1. Fetch all user profiles
    console.log("Fetching all user IDs...");
    const profileRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles?select=id`, {
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });
    const ids = (await profileRes.json()).map(p => p.id);
    console.log(`Found ${ids.length} users.`);

    // 2. Sequential Sync
    let count = 0;
    for (const id of ids) {
        count++;
        console.log(`[${count}/${ids.length}] Syncing user: ${id}...`);
        try {
            const res = await fetch(`${SUPABASE_URL}/functions/v1/sync-academic-stats`, {
                method: 'POST',
                headers: { "Authorization": `Bearer ${SUPABASE_KEY}`, "Content-Type": "application/json" },
                body: JSON.stringify({ user_id: id })
            });
            if (!res.ok) {
                console.error(`  Failed to sync user ${id}: ${res.status}`);
            }
        } catch (e) {
            console.error(`  Error syncing user ${id}:`, e.message);
        }
        
        // Minor delay to be gentle on CPU/DB
        await new Promise(r => setTimeout(r, 100));
    }

    console.log("--- Global Academic Sync Complete ---");
}

globalSync().catch(console.error);
