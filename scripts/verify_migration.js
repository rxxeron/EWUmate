const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

// ----------------------------------------------------
// ⚠️ Set your CREDENTIALS here before running! ⚠️
// ----------------------------------------------------

// 1. Firebase Service Account Key Path
//    Ensure 'serviceAccountKey.json' is in this folder or provide full path
const FIREBASE_SERVICE_KEY_PATH = 'C:/Users/RH/Documents/EWUmate/scripts/service-accounts.json';

// 2. Supabase Credentials
//    Found in Dashboard -> Settings -> API
const SUPABASE_URL = 'https://jwygjihrbwxhehijldiz.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc'; // MUST use SERVICE_ROLE key, not ANON key

// ----------------------------------------------------

async function main() {
    console.log("🚀 Starting Migration Check...");

    // --- Connector: Firebase ---
    if (!fs.existsSync(FIREBASE_SERVICE_KEY_PATH)) {
        console.error(`❌ Missing Firebase Key at: ${FIREBASE_SERVICE_KEY_PATH}`);
        console.error("   Please place 'serviceAccountKey.json' in scripts/ folder.");
        process.exit(1);
    }

    try {
        const serviceAccount = require(FIREBASE_SERVICE_KEY_PATH);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        console.log("✅ Custom check: Firebase Initialized");
    } catch (e) {
        console.error("❌ Firebase Init Error:", e.message);
        process.exit(1);
    }

    // --- Connector: Supabase ---
    if (SUPABASE_SERVICE_ROLE_KEY === 'YOUR_SUPABASE_SERVICE_ROLE_KEY') {
        console.error("❌ Missing Supabase Service Role Key.");
        console.error("   Please update the script with your key.");
        process.exit(1);
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
        auth: {
            autoRefreshToken: false,
            persistSession: false
        }
    });

    // --- Check: Users ---
    console.log("\n--- Checking User Counts ---");

    // Firebase Users
    let firebaseCount = 0;
    let nextPageToken;
    try {
        do {
            const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
            firebaseCount += listUsersResult.users.length;
            nextPageToken = listUsersResult.pageToken;
        } while (nextPageToken);
        console.log(`🔥 Firebase Users: ${firebaseCount}`);
    } catch (e) {
        console.error("❌ Error listing Firebase users:", e);
    }

    // Supabase Users
    try {
        const { count, error } = await supabase.auth.admin.listUsers();
        // listUsers paginates, verify total count logic or just check first page size if small project
        // Better: use count option if available or loop
        // Supabase JS admin.listUsers returns paginated list.
        // Let's assume < 50 for now or loop.
        let supabaseCount = 0;
        let page = 1;
        const PER_PAGE = 50;

        while (true) {
            const { data: { users }, error } = await supabase.auth.admin.listUsers({ page: page, perPage: PER_PAGE });
            if (error) throw error;
            supabaseCount += users.length;
            if (users.length < PER_PAGE) break;
            page++;
        }
        console.log(`⚡ Supabase Users: ${supabaseCount}`);

        if (firebaseCount === supabaseCount) {
            console.log("✅ Counts Match!");
        } else {
            console.log(`⚠️ Mismatch: ${Math.abs(firebaseCount - supabaseCount)} users missing.`);
        }

    } catch (e) {
        console.error("❌ Error listing Supabase users:", e);
    }

    // --- Check: Firestore vs Supabase DB ---
    // If you have specific collections to check, add logic here.
    // Example: 'courses_Spring2026'

    console.log("\nDone.");
}

main();
