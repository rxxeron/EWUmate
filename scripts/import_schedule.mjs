// scripts/import_schedule.mjs
// Run with: node scripts/import_schedule.mjs

import { initializeApp } from 'firebase/app';
import { getFirestore, writeBatch, doc, collection } from 'firebase/firestore';
import { getStorage, ref, getBytes, listAll } from 'firebase/storage';
import * as XLSX from 'xlsx';

// --- CONFIGURATION ---
// Paste your config if not identical to the seed script
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
const storage = getStorage(app);

// Helper to make string safe for IDs
const sanitize = (str) => str?.toString().trim() || "";

const processExcelFile = async (semesterName, fileData) => {
  console.log(`\n📘 Processing Semester: ${semesterName}`);
  
  // 1. Parse Excel
  const workbook = XLSX.read(fileData, { type: 'array' });
  const firstSheetName = workbook.SheetNames[0];
  const worksheet = workbook.Sheets[firstSheetName];
  
  // Convert to JSON
  const rawData = XLSX.utils.sheet_to_json(worksheet);
  console.log(`   Found ${rawData.length} rows in the Excel file.`);

  if (rawData.length === 0) {
    console.warn("   ⚠️ Sheet is empty!");
    return;
  }

  // 2. Map Excel Columns to our Schema
  // Heuristic: Try to find columns names dynamically
  const sampleRow = rawData[0];
  const keys = Object.keys(sampleRow);
  console.log("   Columns found:", keys.join(", "));

  // Detect proper keys
  const colCode = keys.find(k => /course|code/i.test(k)) || keys[0];
  const colName = keys.find(k => /name|title/i.test(k)) || keys[1];
  const colDay = keys.find(k => /day|time/i.test(k)) || "Day"; // Assuming mixed or separate
  const colTime = keys.find(k => /time/i.test(k)) || "Time";
  const colRoom = keys.find(k => /room/i.test(k)) || "Room";
  const colSection = keys.find(k => /sec/i.test(k)) || "Section";
  const colFaculty = keys.find(k => /faculty|initial/i.test(k)) || "Faculty";

  // 3. Prepare Writes
  const COLLECTION_NAME = `courses_${semesterName}`; // e.g., courses_Spring2026
  console.log(`   Writing to Firestore Collection: ${COLLECTION_NAME}`);

  let batch = writeBatch(db);
  let operationCount = 0;
  let batchCount = 0;

  for (const row of rawData) {
    // Generate Document ID: COURSE_SECTION (e.g. "ICE109_1")
    const code = sanitize(row[colCode]);
    const section = sanitize(row[colSection]) || "1";
    
    if (!code) continue; // skip empty rows

    const docId = `${code}_${section}`.replace(/\s+/g, '').toUpperCase();
    
    // Parse Dept
    let dept = "General";
    if (code.startsWith("CSE") || code.startsWith("ICE")) dept = "CSE Dept";
    else if (code.startsWith("MAT") || code.startsWith("PHY")) dept = "MPS Dept";
    else if (code.startsWith("ENG")) dept = "English Dept";

    const courseData = {
      docId: docId,
      courseName: sanitize(row[colName]) || "Unknown Course",
      dept: dept,
      faculty: sanitize(row[colFaculty]),
      room: sanitize(row[colRoom]),
      // For simplicity, we assume single schedule entry per row. 
      // If the excel has multiple rows for same class, this overwrites.
      // Ideally, we'd group them. For now, we take row-by-row.
      schedule: [
        {
          day: sanitize(row[colDay]) || "TBA",
          // Basic Time Parser (assumes "08:30-10:00" or similar)
          startTime: (sanitize(row[colTime]).split('-')[0] || "00:00").trim(),
          endTime: (sanitize(row[colTime]).split('-')[1] || "00:00").trim(),
        }
      ]
    };

    const ref = doc(db, COLLECTION_NAME, docId);
    batch.set(ref, courseData);
    operationCount++;

    // Firestore Batch limit is 500
    if (operationCount >= 400) {
        await batch.commit();
        console.log(`   Saved batch ${++batchCount}...`);
        batch = writeBatch(db);
        operationCount = 0;
    }
  }

  if (operationCount > 0) {
    await batch.commit();
    console.log(`   Saved final batch.`);
  }
  console.log("   ✅ Processing Complete.");
};

const run = async () => {
  console.log("🔍 Scanning 'facultylist' folder in Storage...");
  
  try {
    const listRef = ref(storage, 'facultylist');
    const res = await listAll(listRef);
    
    if (res.items.length === 0) {
      console.error("❌ No files found in 'facultylist' folder.");
      return;
    }

    for (const itemRef of res.items) {
      const fileName = itemRef.name; // e.g. "Faculty List Spring 2026.xlsx"
      
      // Check for Excel
      if (!fileName.endsWith('.xlsx')) {
        console.log(`Skipping non-excel file: ${fileName}`);
        continue;
      }

      // Extract Semester Name
      // Logic: "Faculty List Spring 2026.xlsx" -> "Spring2026"
      let semesterIdentifier = "";
      if (fileName.includes("Spring")) semesterIdentifier = "Spring";
      else if (fileName.includes("Summer")) semesterIdentifier = "Summer";
      else if (fileName.includes("Fall")) semesterIdentifier = "Fall";
      
      const yearMatch = fileName.match(/20\d{2}/);
      const year = yearMatch ? yearMatch[0] : "";

      if (semesterIdentifier && year) {
        const dbSafeName = `${semesterIdentifier}${year}`; // Spring2026
        
        console.log(`\n⬇️  Downloading ${fileName}...`);
        const buffer = await getBytes(itemRef);
        
        await processExcelFile(dbSafeName, buffer);
        
      } else {
        console.warn(`Could not determine semester from filename: ${fileName}`);
      }
    }

  } catch (error) {
    console.error("Error running script:", error);
  }
};

run();
