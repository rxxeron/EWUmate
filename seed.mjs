// seed.mjs
// Run this using: node seed.mjs

import { initializeApp } from 'firebase/app';
import { getFirestore, doc, setDoc } from 'firebase/firestore';

// --- PASTE YOUR CONFIG HERE IF IT DOESN'T IMPORT CORRECTLY ---
// Since we are running in Node, sometimes relative imports are tricky.
// Just paste the content of firebaseConfig.js here for the script.
// Replace the config below with your REAL keys from firebaseConfig.js
const firebaseConfig = {
  apiKey: "AIzaSyBt903u1TAf3xYWOSeTSz5Ct3U2FFMyJUI",
  authDomain: "ewu-stu-togo.firebaseapp.com",
  projectId: "ewu-stu-togo",
  storageBucket: "ewu-stu-togo.firebasestorage.app",
  messagingSenderId: "999077106764",
  appId: "1:999077106764:web:566201d37bd8cadd1d50e9",
  measurementId: "G-WMX8KZNVE5"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

const seedData = async () => {
  console.log("🌱 Starting Database Seed...");

  try {
    // 1. Create Academic Calendar
    console.log("... Writing Academic Calendar");
    await setDoc(doc(db, "academic_events", "Spring2026"), {
      semesterStart: "2026-01-11",
      advisingStart: "2026-04-15",
      holidays: [
        { date: "2026-02-21", name: "International Mother Language Day" },
        { date: "2026-03-26", name: "Independence Day" }
      ],
      events: []
    });

    // 2. Create Setup User
    console.log("... Writing User Profile (student_1)");
    await setDoc(doc(db, "users", "student_1"), {
      name: "Test Student",
      enrolledSections: ["ICE109_1", "MAT102_2"]
    });

    // 3. Create Course 1: ICE109
    console.log("... Writing Course ICE109_1");
    await setDoc(doc(db, "semester_courses", "ICE109_1"), {
      docId: "ICE109_1",
      courseName: "Structured Programming",
      dept: "CSE Dept",
      room: "302",
      schedule: [
        { day: "Sunday", startTime: "08:30", endTime: "10:00" },
        { day: "Tuesday", startTime: "08:30", endTime: "10:00" }
      ]
    });

    // 4. Create Course 2: MAT102
    console.log("... Writing Course MAT102_2");
    await setDoc(doc(db, "semester_courses", "MAT102_2"), {
      docId: "MAT102_2",
      courseName: "Calculus II",
      dept: "MPS Dept",
      room: "405",
      schedule: [
        { day: "Monday", startTime: "10:00", endTime: "11:30" },
        { day: "Wednesday", startTime: "10:00", endTime: "11:30" }
      ]
    });

    console.log("✅ Success! Database populated.");
    console.log("👉 Now refresh your app to see the schedule.");
  } catch (error) {
    console.error("❌ Error seeding database:", error);
  }
};

seedData();
