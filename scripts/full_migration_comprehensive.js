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

async function migrate() {
    console.log("🚀 Starting Comprehensive Migration...");

    // 1. METADATA
    console.log("\n📦 Migrating Metadata...");
    const metaSnap = await db.collection('metadata').get();
    for (const doc of metaSnap.docs) {
        if (doc.id === 'courses') {
            const list = doc.data().list || [];
            console.log(`   🛠️ Processing course_metadata list (${list.length} items)...`);
            const chunks = [];
            for (let i = 0; i < list.length; i += 100) chunks.push(list.slice(i, i + 100));

            for (const chunk of chunks) {
                await supabase.from('course_metadata').upsert(chunk.map(c => ({
                    code: c.code,
                    name: c.name,
                    credits: c.credits,
                    credit_val: c.creditVal
                })));
            }
        } else {
            await supabase.from('metadata').upsert({ id: doc.id, data: doc.data() });
            console.log(`   ✅ Metadata: ${doc.id}`);
        }
    }

    // 2. CONFIG
    console.log("\n⚙️ Migrating Config...");
    const configSnap = await db.collection('config').get();
    for (const doc of configSnap.docs) {
        await supabase.from('config').upsert({ key: doc.id, value: doc.data() });
    }

    // 3. SEMESTER DATA (Dynamic Collections)
    console.log("\n📅 Migrating Semester Data...");
    const semesterCols = JSON.parse(fs.readFileSync('./scripts/semester_collections.json', 'utf8'));
    for (const entry of semesterCols) {
        console.log(`   📥 Migrating ${entry.collection}...`);
        const snap = await db.collection(entry.collection).get();
        const rows = snap.docs.map(doc => {
            const d = doc.data();
            if (entry.type === 'courses') {
                return {
                    doc_id: doc.id,
                    semester: entry.semester,
                    code: d.code,
                    section: d.section,
                    course_name: d.courseName,
                    credits: d.credits,
                    capacity: d.capacity,
                    type: d.type,
                    sessions: d.sessions
                };
            } else if (entry.type === 'calendar') {
                return {
                    doc_id: doc.id,
                    semester: entry.semester,
                    date: d.date,
                    day: d.day,
                    event: d.event,
                    type: d.type
                };
            }
        });

        if (rows.length > 0) {
            const table = entry.type === 'courses' ? 'courses' : 'calendar';
            const { error } = await supabase.from(table).upsert(rows);
            if (error) console.error(`      ❌ Error migrating ${entry.collection}:`, error.message);
            else console.log(`      ✅ Migrated ${rows.length} rows to ${table}.`);
        }
    }

    // 4. ADVISING SCHEDULES
    console.log("\n📑 Migrating Advising Schedules...");
    const advisingSnap = await db.collection('advising_schedules').get();
    for (const doc of advisingSnap.docs) {
        const d = doc.data();
        await supabase.from('advising_schedules').upsert({
            doc_id: doc.id,
            semester: d.semester,
            slots: d.slots,
            uploaded_at: d.uploadedAt ? new Date(d.uploadedAt._seconds * 1000) : null
        });
    }

    // 5. USERS & SUBCOLLECTIONS
    console.log("\n👥 Migrating Users & Subcollections...");
    const userSnap = await db.collection('users').get();
    for (const doc of userSnap.docs) {
        const u = doc.data();
        const uid = doc.id;
        console.log(`   👤 User: ${u.email || uid}`);

        // A. Auth + Profile
        try {
            let supabaseId;

            // Step A: Create Auth User (using Supabase-generated UUID)
            const { data: authData, error: authError } = await supabase.auth.admin.createUser({
                email: u.email,
                email_confirm: true,
                password: 'temp-password-123'
            });

            if (authError && authError.message.includes('already exists')) {
                // If user exists, find their ID
                const { data: listData } = await supabase.auth.admin.listUsers();
                const existing = listData.users.find(user => user.email === u.email);
                supabaseId = existing ? existing.id : null;
            } else if (authError) {
                console.error(`      ❌ Auth Error: ${authError.message}`);
                continue;
            } else {
                supabaseId = authData.user.id;
            }

            if (!supabaseId) {
                console.error(`      ❌ Skip: Could not determine Supabase ID for ${u.email}`);
                continue;
            }

            await supabase.from('profiles').upsert({
                id: supabaseId,
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
            console.log(`      ✅ Profile Linked.`);

            // B. Academic Data
            const acadSnap = await db.collection('users').doc(uid).collection('academic_data').get();
            for (const acadDoc of acadSnap.docs) {
                const ad = acadDoc.data();
                await supabase.from('academic_data').upsert({
                    user_id: supabaseId,
                    cgpa: ad.cgpa,
                    total_credits_earned: ad.totalCreditsEarned,
                    remained_credits: ad.remainedCredits,
                    semesters: ad.semesters
                });
            }

            // C. Schedules
            const schedSnap = await db.collection('users').doc(uid).collection('schedule').get();
            for (const schedDoc of schedSnap.docs) {
                await supabase.from('user_schedules').upsert({
                    user_id: supabaseId,
                    weekly_template: schedDoc.data().weeklyTemplate
                });
            }

            // D. Semester Progress
            const progSnap = await db.collection('users').doc(uid).collection('semesterProgress').get();
            for (const progDoc of progSnap.docs) {
                const pd = progDoc.data();
                await supabase.from('semester_progress').upsert({
                    user_id: supabaseId,
                    semester_code: pd.semesterCode,
                    summary: pd.summary,
                    last_updated: pd.lastUpdated ? new Date(pd.lastUpdated._seconds * 1000) : null
                });
            }

            // E. FCM Tokens
            const fcmSnap = await db.collection('users').doc(uid).collection('fcm_tokens').get();
            for (const fcmDoc of fcmSnap.docs) {
                await supabase.from('fcm_tokens').upsert({
                    user_id: supabaseId,
                    token: fcmDoc.id,
                    device_info: fcmDoc.data()
                });
            }

        } catch (e) {
            console.error(`      ❌ Error for user ${uid}:`, e.message);
        }
    }

    console.log("\n🎉 COMPREHENSIVE MIGRATION SUCCESSFUL!");
}

migrate();
