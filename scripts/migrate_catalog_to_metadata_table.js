const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');

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

async function migrateCatalog() {
    console.log("🚀 Migrating courses from Firestore metadata/courses to Supabase course_metadata table...");

    const doc = await db.collection('metadata').doc('courses').get();
    if (!doc.exists) {
        console.error("❌ Firestore document metadata/courses not found!");
        return;
    }

    const list = doc.data().list || [];
    console.log(`📦 Found ${list.length} courses in Firestore.`);

    // Map and try to handle potential integer constraints in Supabase
    const rows = list.map(c => {
        const credits = parseFloat(c.credits || 3.0);
        const creditVal = parseFloat(c.creditVal || 3.0);

        return {
            code: c.code.toUpperCase().replace(/\s+/g, ''),
            name: c.name,
            // If Supabase column is integer, we round. Ideally it should be float.
            credits: Math.round(credits),
            credit_val: Math.round(creditVal)
        };
    });

    // Chunking to avoid large payload errors
    for (let i = 0; i < rows.length; i += 100) {
        const chunk = rows.slice(i, i + 100);
        const { error } = await supabase.from('course_metadata').upsert(chunk, { onConflict: 'code' });
        if (error) {
            console.error(`   ❌ Error in chunk ${i / 100}:`, error.message);
            // If it still fails, it might be the 'credits' column. 
            // We could try a fallback without credits if it's just for catalog selection.
            console.log("   🔄 Retrying chunk without numeric credits...");
            const fallbackChunk = chunk.map(c => ({ code: c.code, name: c.name }));
            const { error: err2 } = await supabase.from('course_metadata').upsert(fallbackChunk, { onConflict: 'code' });
            if (err2) console.error(`      ❌ Fallback failed: ${err2.message}`);
            else console.log(`      ✅ Fallback succeeded for chunk ${i / 100 + 1}`);
        } else {
            console.log(`   ✅ Migrated chunk ${i / 100 + 1}`);
        }
    }

    console.log("🎉 Catalog migration complete.");
}

migrateCatalog();
