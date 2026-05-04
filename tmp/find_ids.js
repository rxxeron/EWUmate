const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc";

async function findIds() {
    const id1 = "4d0ce88c-0fe7-4a00-bde9-8eca9ebd08fa";
    const id2 = "1f791ac9-80ef-4a77-9e37-835b72fec7fd";

    console.log(`--- Searching for ${id1} ---`);
    // Check Auth
    const auth1 = await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${id1}`, {
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });
    if (auth1.ok) {
        const u = await auth1.json();
        console.log(`Auth Found: Email=${u.email}, CreatedAt=${u.created_at}`);
    } else {
        console.log(`Auth Not Found`);
    }

    // Check Profile
    const prof1 = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${id1}`, {
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });
    const p1 = await prof1.json();
    if (p1.length > 0) {
        console.log(`Profile Found: Name=${p1[0].full_name}, StudentID=${p1[0].student_id}`);
    } else {
        console.log(`Profile Not Found`);
    }

    console.log(`\n--- Searching for ${id2} ---`);
    // Check Auth
    const auth2 = await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${id2}`, {
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });
    if (auth2.ok) {
        const u = await auth2.json();
        console.log(`Auth Found: Email=${u.email}, CreatedAt=${u.created_at}`);
    } else {
        console.log(`Auth Not Found`);
    }

    // Check Profile
    const prof2 = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${id2}`, {
        headers: { "apikey": SUPABASE_KEY, "Authorization": `Bearer ${SUPABASE_KEY}` }
    });
    const p2 = await prof2.json();
    if (p2.length > 0) {
        console.log(`Profile Found: Name=${p2[0].full_name}, StudentID=${p2[0].student_id}`);
    } else {
        console.log(`Profile Not Found`);
    }
}
findIds().catch(console.error);
