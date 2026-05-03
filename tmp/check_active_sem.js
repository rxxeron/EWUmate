const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY";

async function checkState() {
    console.log("--- Active Semester Info ---");
    const activeRes = await fetch(`${SUPABASE_URL}/rest/v1/active_semester?select=*`, {
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });
    const activeData = await activeRes.json();
    console.log(JSON.stringify(activeData, null, 2));

    console.log("\n--- Pending Notifications for a Tri-Semester Student (example) ---");
    // Find a tri-semester student
    const profRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles?track=eq.tri_semester&limit=1&select=id,full_name`, {
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });
    const profiles = await profRes.json();
    if (profiles.length > 0) {
        const userId = profiles[0].id;
        console.log(`Checking notifications for ${profiles[0].full_name} (${userId})`);
        const notifRes = await fetch(`${SUPABASE_URL}/rest/v1/notifications?user_id=eq.${userId}&is_dispatched=eq.false&select=*`, {
            headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
        });
        const notifs = await notifRes.json();
        console.log(JSON.stringify(notifs, null, 2));
    }
}
checkState().catch(console.error);
