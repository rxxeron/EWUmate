
import { initializeApp } from 'firebase/app';
import { getFirestore, doc, setDoc } from 'firebase/firestore';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const { COURSE_CATALOG, DEPARTMENTS } = require('./data/seed-data.js'); // Import from local backup

// Configuration
const firebaseConfig = {
  apiKey: "AIzaSyBt903u1TAf3xYWOSeTSz5Ct3U2FFMyJUI",
  authDomain: "ewu-stu-togo.firebaseapp.com",
  projectId: "ewu-stu-togo",
  storageBucket: "ewu-stu-togo.firebasestorage.app",
  messagingSenderId: "999077106764",
  appId: "1:999077106764:web:566201d37bd8cadd1d50e9",
  measurementId: "G-WMX8KZNVE5"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// Data
// const DEPARTMENTS = [ ... ] // Removed local definition, imported from seed-data.js

async function uploadCatalog() {
  try {
    console.log('Starting upload...');

    // 1. Upload Departments
    // We store this in a 'metadata' collection, document 'departments'
    console.log('Uploading Departments list...');
    await setDoc(doc(db, 'metadata', 'departments'), {
      updatedAt: new Date().toISOString(),
      list: DEPARTMENTS
    });
    console.log('Departments uploaded successfully.');

    // 2. Upload Course Catalog
    // We store this in a 'metadata' collection, document 'courses'
    // Storing as a single list for now for easier client-side searching
    // If list grows > 1000 items, we should split or use a subcollection
    console.log(`Uploading Course Catalog (${COURSE_CATALOG.length} courses)...`);
    await setDoc(doc(db, 'metadata', 'courses'), {
      updatedAt: new Date().toISOString(),
      catalog: COURSE_CATALOG
    });
    console.log('Course Catalog uploaded successfully.');
    
    console.log('Upload complete! You can now configure your app to fetch from "metadata/departments" and "metadata/courses".');
    process.exit(0);
  } catch (error) {
    console.error('Error uploading data:', error);
    process.exit(1);
  }
}

uploadCatalog();
