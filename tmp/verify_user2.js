const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY";

async function verify() {
    const profileRes = await fetch("\/rest/v1/profiles?limit=1&select=*", {
        headers: {
            "apikey": SUPABASE_KEY,
            "Authorization": "Bearer \"
        }
    });
    const profiles = await profileRes.json();
    console.log(profiles[0]);
}

verify().catch(console.error);
