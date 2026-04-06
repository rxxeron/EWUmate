const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc";
const USER_ID = "4efd4ebc-a70b-404c-9934-0db39fec8f99";

async function verify() {
    console.log(`--- Verifying User Data for ${USER_ID} ---`);
    
    // 1. Trigger Sync first to make sure totals are recalculated
    console.log("Triggering Sync Engine...");
    await fetch(`${SUPABASE_URL}/functions/v1/sync-academic-stats`, {
        method: 'POST',
        headers: {
            "Authorization": `Bearer ${SUPABASE_KEY}`,
            "Content-Type": "application/json"
        },
        body: JSON.stringify({ user_id: USER_ID })
    });

    // 2. Fetch Summaries
    const summariesRes = await fetch(`${SUPABASE_URL}/rest/v1/semester_summaries?user_id=eq.${USER_ID}&select=*`, {
        headers: {
            "apikey": SUPABASE_KEY,
            "Authorization": `Bearer ${SUPABASE_KEY}`
        }
    });
    const summaries = await summariesRes.json();
    
    // 3. Fetch Profile
    const profileRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${USER_ID}&select=*`, {
        headers: {
            "apikey": SUPABASE_KEY,
            "Authorization": `Bearer ${SUPABASE_KEY}`
        }
    });
    const profiles = await profileRes.json();

    console.log("\n--- PROFILE TOTALS ---");
    if (profiles.length > 0) {
        console.log(`Total Credits: ${profiles[0].total_credits_earned}`);
        console.log(`GPA: ${profiles[0].cgpa}`);
    }

    console.log("\n--- SEMESTER SUMMARIES ---");
    summaries.sort((a,b) => a.semester_code.localeCompare(b.semester_code));
    summaries.forEach(s => {
        console.log(`[${s.semester_code}] Credits: ${s.credits_earned}, GPA: ${s.gpa}`);
    });
}

verify().catch(console.error);
