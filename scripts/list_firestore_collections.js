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

async function listCollections() {
    console.log("🔍 Listing all Firestore collections...");
    const collections = await db.listCollections();

    if (collections.length === 0) {
        console.log("❌ No collections found.");
        return;
    }

    for (const collection of collections) {
        const snap = await collection.limit(1).get();
        console.log(`- ${collection.id} (${snap.size > 0 ? 'contains data' : 'empty'})`);
    }
}

listCollections();
