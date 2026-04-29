const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY";

async function verify() {
    const profileRes = await fetch(SUPABASE_URL + "/rest/v1/programs?limit=1&select=*", {
        headers: {
            "apikey": SUPABASE_KEY,
            "Authorization": "Bearer " + SUPABASE_KEY
        }
    });
    console.log(await profileRes.json());
}
verify();
