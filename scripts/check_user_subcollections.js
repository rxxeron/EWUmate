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

async function checkSubcollections() {
    const users = [
        'V7HLsnB70XNqb9Kt2NMZqBStiCC2',
        'Yv12jlEbAzTs6c3ogogxO1VLNtt2',
        'x97Dn9udgRQ9CmRaitmNL5TDrwP2'
    ];

    for (const uid of users) {
        console.log(`\n🔍 Checking sub-collections for User: ${uid}`);
        const docRef = db.collection('users').doc(uid);
        const subcollections = await docRef.listCollections();

        if (subcollections.length === 0) {
            console.log(`   No sub-collections found.`);
            continue;
        }

        for (const sub of subcollections) {
            const snap = await sub.limit(1).get();
            console.log(`   - Found Sub-collection: ${sub.id}`);
            if (!snap.empty) {
                console.log(`     Sample Data:`, JSON.stringify(snap.docs[0].data(), null, 2).substring(0, 200) + '...');
            }
        }
    }
}

checkSubcollections();
