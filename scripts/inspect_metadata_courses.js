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

async function inspectMetadataCourses() {
    console.log("🔍 Inspecting metadata/courses...");
    const doc = await db.collection('metadata').doc('courses').get();
    if (!doc.exists) {
        console.log("❌ metadata/courses not found.");
        return;
    }

    const data = doc.data();
    console.log("Fields in metadata/courses:", Object.keys(data));

    if (data.list && Array.isArray(data.list)) {
        console.log(`Found 'list' with ${data.list.length} items.`);
        console.log("Sample item:", JSON.stringify(data.list[0], null, 2));
    } else {
        console.log("Data structure:", JSON.stringify(data, null, 2).substring(0, 500));
    }
}

inspectMetadataCourses();
