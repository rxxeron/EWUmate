const admin = require('firebase-admin');
const fs = require('fs');

const FIREBASE_SERVICE_KEY_PATH = './service-accounts.json';
const serviceAccount = require(FIREBASE_SERVICE_KEY_PATH);

if (admin.apps.length === 0) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}
const db = admin.firestore();

async function listAll() {
    console.log("🚀 Mapping Full Firestore Schema...");
    const collections = await db.listCollections();

    for (const col of collections) {
        console.log(`\n📦 Collection: ${col.id}`);
        const snap = await col.limit(1).get();
        if (!snap.empty) {
            console.log(`   Fields: ${Object.keys(snap.docs[0].data()).join(', ')}`);

            // Check for subcollections in the first doc
            const subCols = await snap.docs[0].ref.listCollections();
            for (const sub of subCols) {
                console.log(`   ↳ Sub-collection: ${sub.id}`);
            }
        } else {
            console.log("   (Empty)");
        }
    }
}

listAll();
