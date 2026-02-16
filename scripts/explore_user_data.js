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

async function exploreUserData() {
    console.log("🔍 Exploring User-related data in Firestore...");

    // Checking common user-related collections
    const userCollections = ['users', 'profiles', 'progress', 'semester_progress'];

    for (const colName of userCollections) {
        console.log(`\n--- Collection: ${colName} ---`);
        const snapshot = await db.collection(colName).limit(3).get();

        if (snapshot.empty) {
            console.log(`   (Empty or does not exist)`);
            continue;
        }

        console.log(`   Found ${snapshot.size} sample docs:`);
        snapshot.forEach(doc => {
            console.log(`   ID: ${doc.id}`);
            console.log('   Data:', JSON.stringify(doc.data(), null, 2).substring(0, 200) + '...');
        });
    }
}

exploreUserData();
