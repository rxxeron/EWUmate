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

async function findSemesters() {
    console.log("🔍 Scanning for semester-specific collections...");
    const collections = await db.listCollections();

    const coursesRegex = /^courses_(.+)$/;
    const calendarRegex = /^calendar_(.+)$/;
    const examsRegex = /^exams_(.+)$/;

    const semesters = new Set();
    const specificCollections = [];

    for (const col of collections) {
        let match;
        if (match = col.id.match(coursesRegex)) {
            semesters.add(match[1]);
            specificCollections.push({ type: 'courses', semester: match[1], collection: col.id });
        } else if (match = col.id.match(calendarRegex)) {
            semesters.add(match[1]);
            specificCollections.push({ type: 'calendar', semester: match[1], collection: col.id });
        } else if (match = col.id.match(examsRegex)) {
            semesters.add(match[1]);
            specificCollections.push({ type: 'exams', semester: match[1], collection: col.id });
        }
    }

    console.log("Found Semesters:", Array.from(semesters));
    console.log("Specific Collections:", JSON.stringify(specificCollections, null, 2));

    fs.writeFileSync('./scripts/semester_collections.json', JSON.stringify(specificCollections, null, 2));
}

findSemesters();
