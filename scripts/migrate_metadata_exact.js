const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

// ----------------------------------------------------
// ⚠️ CREDENTIALS ⚠️
// ----------------------------------------------------
const PROJECT_REF = 'jwygjihrbwxhehijldiz';
const SUPABASE_URL = `https://${PROJECT_REF}.supabase.co`;
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';
const FIREBASE_SERVICE_KEY_PATH = './service-accounts.json';

// Init Firebase
const serviceAccount = require(FIREBASE_SERVICE_KEY_PATH);
if (admin.apps.length === 0) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}
const db = admin.firestore();

// Init Supabase
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false }
});

async function migrateMetadataExact() {
    console.log("🚀 Starting Metadata Migration (Exact Clone)...");

    // 1. Read 'metadata' collection from Firestore
    const snapshot = await db.collection('metadata').get();

    if (snapshot.empty) {
        console.log("❌ No documents found in Firestore 'metadata'.");
        return;
    }

    console.log(`Found ${snapshot.size} documents to migrate.`);

    // 2. Insert into Supabase 'metadata' table
    // Assuming table exists: CREATE TABLE metadata (id text primary key, data jsonb);

    let successCount = 0;

    for (const doc of snapshot.docs) {
        const docData = doc.data();
        const payload = {
            id: doc.id,
            data: docData // Store entire document as JSONB
        };

        const { error } = await supabase
            .from('metadata')
            .upsert(payload);

        if (error) {
            console.error(`❌ Failed to migrate ${doc.id}: ${error.message}`);
            console.error(`   (Make sure 'metadata' table exists!)`);
        } else {
            console.log(`✅ Migrated: ${doc.id}`);
            successCount++;
        }
    }

    console.log(`\n🎉 Migration Complete: ${successCount}/${snapshot.size} documents.`);
    if (successCount === 0) {
        console.log("\n⚠️ TIP: Did you create the table?");
        console.log("   Run this SQL in Supabase Dashboard:");
        console.log("   CREATE TABLE IF NOT EXISTS metadata (id TEXT PRIMARY KEY, data JSONB);");
        console.log("   ALTER TABLE metadata ENABLE ROW LEVEL SECURITY;");
        console.log("   CREATE POLICY \"Public Read\" ON metadata FOR SELECT USING (true);");
    }
}

migrateMetadataExact();
