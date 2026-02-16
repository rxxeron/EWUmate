const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

// Config
const PROJECT_REF = 'jwygjihrbwxhehijldiz';
const SUPABASE_URL = `https://${PROJECT_REF}.supabase.co`;
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';
const FIREBASE_SERVICE_KEY_PATH = './service-accounts.json';

// Init
const serviceAccount = require(FIREBASE_SERVICE_KEY_PATH);
if (admin.apps.length === 0) { admin.initializeApp({ credential: admin.credential.cert(serviceAccount) }); }
const db = admin.firestore();
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function migrateEverything() {
    console.log("🚀 Starting Full Migration (Users + Metadata)...");

    // 1. MAPPING METADATA
    console.log("\n📦 Migrating Metadata...");
    const metaSnap = await db.collection('metadata').get();
    for (const doc of metaSnap.docs) {
        await supabase.from('metadata').upsert({ id: doc.id, data: doc.data() });
        console.log(`   ✅ Metadata: ${doc.id}`);
    }

    // 2. MAPPING USERS (Auth + Profiles)
    console.log("\n👥 Migrating Users...");
    const userSnap = await db.collection('users').get();

    for (const doc of userSnap.docs) {
        const u = doc.data();
        console.log(`   Processing ${u.email || doc.id}...`);

        try {
            // Step A: Create Auth User (if not exist)
            const { data: authData, error: authError } = await supabase.auth.admin.createUser({
                id: doc.id, // KEEPING ORIGINAL UID FROM FIREBASE
                email: u.email,
                email_confirm: true,
                password: 'temp-password-123'
            });

            if (authError && authError.message.includes('already exists')) {
                console.log(`      (Auth user already exists)`);
            } else if (authError) {
                console.error(`      ❌ Auth Error: ${authError.message}`);
            }

            // Step B: Create Profile
            const { error: profError } = await supabase.from('profiles').upsert({
                id: doc.id,
                full_name: u.fullName,
                nickname: u.nickname,
                email: u.email,
                photo_url: u.photoURL,
                department: u.department,
                program_id: u.programId,
                admitted_semester: u.admittedSemester,
                onboarding_status: u.onboardingStatus,
                scholarship_status: u.scholarshipStatus,
                last_touch: u.lastTouch ? new Date(u.lastTouch._seconds * 1000) : null
            });

            if (profError) {
                console.error(`      ❌ Profile Error: ${profError.message}`);
            } else {
                console.log(`      ✅ Profile Linked.`);
            }

        } catch (e) {
            console.error(`      ❌ Exception: ${e.message}`);
        }
    }

    console.log("\n🎉 Full Migration Complete!");
}

migrateEverything();
