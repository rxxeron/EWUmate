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

async function inspectMetadata() {
    console.log("🔍 Inspecting 'metadata' collection in Firestore...");

    const snapshot = await db.collection('metadata').get();

    if (snapshot.empty) {
        console.log("❌ Collection 'metadata' is empty or doesn't exist.");
        return;
    }

    console.log(`Found ${snapshot.size} documents.`);
    snapshot.forEach(doc => {
        console.log(`\nDocument ID: ${doc.id}`);
        console.log(JSON.stringify(doc.data(), null, 2));
    });
}

inspectMetadata();
