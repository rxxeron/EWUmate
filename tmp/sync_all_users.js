const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc";

async function syncAll() {
    console.log("Fetching all profile IDs...");
    const profileRes = await fetch(SUPABASE_URL + "/rest/v1/profiles?select=id", {
        headers: {
            "apikey": SUPABASE_KEY,
            "Authorization": "Bearer " + SUPABASE_KEY
        }
    });

    const profiles = await profileRes.json();
    console.log("Found " + profiles.length + " profiles. Starting sync...");

    for (const profile of profiles) {
        console.log("Syncing user: " + profile.id);
        const res = await fetch(SUPABASE_URL + "/functions/v1/sync-academic-stats", {
            method: "POST",
            headers: {
                "Authorization": "Bearer " + SUPABASE_KEY,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({ user_id: profile.id })
        });
        console.log("  -> Success for " + profile.id);
        await new Promise(r => setTimeout(r, 200));
    }
}
syncAll();
