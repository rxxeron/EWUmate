/**
 * Cloud Function to automatically parse Excel and PDF Schedules uploaded to Storage
 * and populate the Firestore database.
 * 
 * Trigger: Storage Object Finalized (Upload)
 * Target Path: facultylist/
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const path = require('path');
const os = require('os');
const fs = require('fs');

// Lazy initialization
let dbInstance = null;
const getDb = () => {
    if (!dbInstance) {
        if (admin.apps.length === 0) {
            admin.initializeApp();
        }
        dbInstance = admin.firestore();
    }
    return dbInstance;
};

// Helper to sanitize strings for ID generation
const sanitize = (str) => str?.toString().trim() || "";

const PROCESSOR_ID = '96e8ee9d1113311'; 
const LOCATION = 'us'; 
const PROJECT_ID = 'ewu-stu-togo'; 

const DOC_TYPES = {
    COURSE: 'COURSE',
    CALENDAR: 'CALENDAR',
    EXAM: 'EXAM'
};

exports.processScheduleUpload = functions.storage.object().onFinalize(async (object) => {
  // Ensure Firebase App is initialized securely for Cold Starts
  getDb(); 

  const fileBucket = object.bucket;
  const filePath = object.name; 
  const fileName = path.basename(filePath);

  let docType = null;
  let collectionPrefix = "";

  // 1. Determine Doc Type from Folder
  if (filePath.startsWith("facultylist/")) {
      docType = DOC_TYPES.COURSE;
      collectionPrefix = "courses_";
  } else if (filePath.startsWith("academiccalendar/")) {
      docType = DOC_TYPES.CALENDAR;
      collectionPrefix = "calendar_";
  } else if (filePath.startsWith("examschedule/")) {
      docType = DOC_TYPES.EXAM;
      collectionPrefix = "exams_";
  } else {
    console.log("File is not in a supported folder (facultylist, academiccalendar, examschedule). Ignoring.");
    return null;
  }

  // 2. Extract Semester ID from filename
  // Logic: "Faculty List Spring 2026.xlsx" -> "Spring2026"
  let semesterIdentifier = "";
  if (fileName.includes("Spring")) semesterIdentifier = "Spring";
  else if (fileName.includes("Summer")) semesterIdentifier = "Summer";
  else if (fileName.includes("Fall")) semesterIdentifier = "Fall";
  
  const yearMatch = fileName.match(/20\d{2}/);
  const year = yearMatch ? yearMatch[0] : "";

  if (!semesterIdentifier || !year) {
    console.log("Could not determine Semester/Year from filename. Ignoring.");
    return null;
  }

  const semesterDocId = `${semesterIdentifier}${year}`; // "Spring2026"
  const collectionName = `${collectionPrefix}${semesterDocId}`; 

  console.log(`Processing ${fileName} as ${docType} for semester ${semesterDocId}...`);

  // 3. Download the file
  const bucket = admin.storage().bucket(fileBucket);
  const tempFilePath = path.join(os.tmpdir(), fileName);
  
  await bucket.file(filePath).download({ destination: tempFilePath });
  console.log('File downloaded locally to', tempFilePath);

  try {
    let dataMap = new Map();

    if (fileName.toLowerCase().endsWith('.xlsx')) {
        console.log("Detecting Excel File. Parsing with XLSX...");
        // Excel currently only supported for Courses, but we can extend later
        if (docType === DOC_TYPES.COURSE) {
             dataMap = await parseExcel(tempFilePath, semesterDocId);
        } else {
             console.log("Excel parsing for Calendar/Exam not yet implemented.");
        }
    } else if (fileName.toLowerCase().endsWith('.pdf')) {
        console.log("Detecting PDF File. Parsing with Document AI...");
        dataMap = await parsePdf(tempFilePath, docType, semesterDocId);
    } else {
        console.log("Unsupported file type. Only .xlsx and .pdf are supported.");
        return null;
    }

    if (dataMap && dataMap.size > 0) {
        await populateFirestore(dataMap, collectionName, fileName);
    } else {
        console.log("No valid data extracted.");
    }

    // Cleanup
    try {
        fs.unlinkSync(tempFilePath);
    } catch(e) {
        console.log("Error deleting temp file", e);
    }

  } catch (error) {
    console.error("Error processing file:", error);
  }

  return null;
});

// --- HELPER FUNCTIONS ---

const populateFirestore = async (dataMap, collectionName, sourceFileName) => {
    const db = getDb();
    
    // 1. Clean up existing records identifying as this source file (Re-upload / Update case)
    if (sourceFileName) {
        console.log(`Cleaning up old records for ${sourceFileName} in ${collectionName}...`);
        const snapshot = await db.collection(collectionName).where('sourceFile', '==', sourceFileName).get();
        if (!snapshot.empty) {
            let deleteBatch = db.batch();
            let deleteCount = 0;
            for (const doc of snapshot.docs) {
                deleteBatch.delete(doc.ref);
                deleteCount++;
                if (deleteCount >= 400) {
                    await deleteBatch.commit();
                    deleteBatch = db.batch();
                    deleteCount = 0;
                }
            }
            if (deleteCount > 0) await deleteBatch.commit();
            console.log(`Deleted ${snapshot.size} old records.`);
        }
    }

    // 2. Insert new records
    let batch = db.batch();
    let operationCount = 0;

    for (const data of dataMap.values()) {
        const ref = db.collection(collectionName).doc(data.docId);
        // Tag data with source file
        const payload = { ...data, sourceFile: sourceFileName || "unknown" };
        
        batch.set(ref, payload);
        operationCount++;

        if (operationCount >= 400) {
            await batch.commit();
            batch = db.batch();
            operationCount = 0;
        }
    }

    if (operationCount > 0) {
      await batch.commit();
    }
    console.log(`Successfully populated ${collectionName} with ${dataMap.size} entries from ${sourceFileName}.`);
};


const parseExcel = async (filePath, semesterId) => {
    const XLSX = require('xlsx');
    const workbook = XLSX.readFile(filePath);
    const firstSheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[firstSheetName];
    
    const rows = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
    if (rows.length === 0) return null;

    // Header Detection
    let headerRowIndex = -1;
    let colMap = {};

    for (let i = 0; i < Math.min(rows.length, 20); i++) {
        const rawRow = rows[i] || [];
        const row = []; 
        for(let k=0; k<rawRow.length; k++) {
            const val = rawRow[k];
            row.push(val ? String(val).toLowerCase().trim() : "");
        }
        
        const hasCourse = row.some(r => r && (r.includes('course') || r.includes('code')));
        const hasTiming = row.some(r => r && (r.includes('timing') || (r.includes('day') && r.includes('time'))));
        
        if (hasCourse && hasTiming) {
            headerRowIndex = i;
            colMap.codeIdx = row.findIndex(r => r && (r.includes('course') || r.includes('code')));
            colMap.nameIdx = row.findIndex(r => r && (r.includes('title') || r.includes('name') || r.includes('description')));
            colMap.secIdx = row.findIndex(r => r && (r.includes('sec')));
            colMap.facultyIdx = row.findIndex(r => r && (r.includes('faculty') || r.includes('initial')));
            colMap.timingIdx = row.findIndex(r => r && (r.includes('timing')));
            colMap.roomIdx = row.findIndex(r => r && (r.includes('room')));
            console.log("Excel Header Found:", JSON.stringify(colMap));
            break;
        }
    }

    if (headerRowIndex === -1) {
        console.log("Excel: Could not find header.");
        return null;
    }

    const coursesMap = new Map();

    for (let i = headerRowIndex + 1; i < rows.length; i++) {
        const row = rows[i];
        if (!row || row.length === 0) continue;

        const code = sanitize(colMap.codeIdx !== -1 ? row[colMap.codeIdx] : null);
        if (!code) continue;

        const section = sanitize(colMap.secIdx !== -1 ? row[colMap.secIdx] : "1") || "1";
        const timingStr = colMap.timingIdx !== -1 ? sanitize(row[colMap.timingIdx]) : "";
        const courseName = sanitize(colMap.nameIdx !== -1 ? row[colMap.nameIdx] : "") || code;
        const faculty = sanitize(colMap.facultyIdx !== -1 ? row[colMap.facultyIdx] : "TBA");
        const room = sanitize(colMap.roomIdx !== -1 ? row[colMap.roomIdx] : "TBA");

        processRowData(coursesMap, code, section, timingStr, courseName, faculty, room, "N/A", semesterId);
    }
    return coursesMap;
}

const parsePdf = async (filePath, docType, semesterId) => {
    // Initialize Client Lazy
    const { DocumentProcessorServiceClient } = require('@google-cloud/documentai');
    
    // We assume the user creates multiple PDFs < 30 pages each if necessary.
    // Document AI has a limit of ~30 pages per synchronous request.

    const client = new DocumentProcessorServiceClient();

    const fileBuffer = fs.readFileSync(filePath);
    const encodedImage = fileBuffer.toString('base64');

    const name = `projects/${PROJECT_ID}/locations/${LOCATION}/processors/${PROCESSOR_ID}`;
    const request = {
        name,
        rawDocument: {
            content: encodedImage,
            mimeType: 'application/pdf',
        },
    };

    console.log(`Sending request to Document AI: ${name} [Type: ${docType}]`);
    const [result] = await client.processDocument(request);
    const { document } = result;

    if (!document || !document.pages) {
        console.log('Document AI returned no pages.');
        return null;
    }

    const dataMap = new Map();

    if (docType === DOC_TYPES.COURSE) {
        // ... (Existing Course Logic)
        const hasTables = document.pages && document.pages.some(p => p.tables && p.tables.length > 0);
        let parsedFromTables = false;

        if (hasTables) {
            console.log("Document AI returned tables. Parsing tables...");
            // Iterate through pages and tables
            for (const page of document.pages) {
                if (!page.tables) continue;
    
                for (const table of page.tables) {
                    // Process Header to find column indices
                    // Document AI separates headerRows and bodyRows.
                    // We assume the first header row has our labels.
                    let colMap = { codeIdx: -1, timingIdx: -1, secIdx: -1, facultyIdx: -1, roomIdx: -1, nameIdx: -1 };
                    
                    // Check Header
                    if (table.headerRows && table.headerRows.length > 0) {
                            const headerCells = table.headerRows[0].cells;
                            headerCells.forEach((cell, idx) => {
                                const text = getCellText(cell, document.text).toLowerCase();
                                if (text.includes('course') || text.includes('code')) colMap.codeIdx = idx;
                                if (text.includes('timing') || text.includes('time')) colMap.timingIdx = idx;
                                if (text.includes('sec')) colMap.secIdx = idx;
                                if (text.includes('faculty') || text.includes('initial')) colMap.facultyIdx = idx;
                                if (text.includes('room')) colMap.roomIdx = idx;
                                if (text.includes('title') || text.includes('name')) colMap.nameIdx = idx;
                            });
                    
                    }
    
                    // Fallback: If header detection failed (sometimes generic), we might assume standard order?
                    // But let's rely on detection for now.
                    if (colMap.codeIdx === -1) {
                         // Attempt standard indices fallback: Code(0), Name(1), Sec(2), Faculty(3), Room(4), Time(5) ? 
                         // This is risky, let's just log and skip for now, but rely on text fallback later.
                         console.log("Table found but header not recognized. Skipping table.");
                         continue; 
                    }
    
                    // Process Body Rows
                    for (const row of table.bodyRows) {
                        const cells = row.cells;
                        
                        const getVal = (idx) => (idx !== -1 && cells[idx]) ? getCellText(cells[idx], document.text).trim() : "";
    
                        const code = sanitize(getVal(colMap.codeIdx));
                        if (!code) continue;
    
                        const section = sanitize(getVal(colMap.secIdx)) || "1";
                        const timingStr = getVal(colMap.timingIdx);
                        const courseName = getVal(colMap.nameIdx) || code;
                        const faculty = getVal(colMap.facultyIdx) || "TBA";
                        const room = getVal(colMap.roomIdx) || "TBA";
    
                        processRowData(dataMap, code, section, timingStr, courseName, faculty, room, "N/A", semesterId);
                        parsedFromTables = true;
                    }
                }
            }
        } 
        
        if (!parsedFromTables) {
            console.log("No tables parsed or Document AI returned no tables. Attempting Fallback Text Parsing...");
            parsePdfText(document.text, dataMap, semesterId);
        }
    } else if (docType === DOC_TYPES.CALENDAR) {
        console.log("Parsing Academic Calendar...");
        parseCalendar(document.text, dataMap);
    } else if (docType === DOC_TYPES.EXAM) {
        console.log("Parsing Exam Schedule...");
        parseExam(document.text, dataMap);
    }
    
    return dataMap;
}

const parseCalendar = (text, dataMap) => {
    // Strategy: The OCR often separates the "Event" column and "Date" column into two distinct blocks of text one after another.
    // We will look for the "Event" header and "Date" header.
    
    const lines = text.split('\n').map(l => l.trim()).filter(l => l);
    
    // Find Headers
    const eventHeaderIdx = lines.findIndex(l => l.toLowerCase() === 'event');
    const dateHeaderIdx = lines.findIndex((l, i) => i > eventHeaderIdx && (l.toLowerCase() === 'date' || l.toLowerCase() === 'day'));

    if (eventHeaderIdx !== -1 && dateHeaderIdx !== -1) {
        // Assume everything between "Event" and "Date" are events
        // And everything after "Date" (skipping "Day", "Time" etc) are dates
        
        const rawEvents = lines.slice(eventHeaderIdx + 1, dateHeaderIdx);
        const rawDates = lines.slice(dateHeaderIdx + 1);

        // Filter out common header noise from Dates like "Day", "Time"
        const cleanDates = rawDates.filter(l => !['day', 'time', 'date'].includes(l.toLowerCase()));
        
        // Improve Event parsing: Join lines that don't look like independent events? 
        // For now, let's treat every non-empty line as an event part.
        // Capturing exact 1:1 mapping with wrapped text is hard without Bounding Boxes, 
        // so we will save them as lists and try to map sequentially as best effort.

        const events = rawEvents.filter(l => l.length > 2); // filter noise
        
        // We will store the data in a robust "List" format rather than Key-Value pairs 
        // if the counts don't match, to avoid data loss.
        
        const count = Math.min(events.length, cleanDates.length);
        
        // Heuristic: If event count is much larger than date count, events likely wrap.
        // We'll try to populate simple objects.
        
        for(let i=0; i<cleanDates.length; i++) {
             // If we have more events than dates, we might need to combine event lines.
             // This is a naive mapping.
             const docId = `CAL_${i}`;
             const eventText = events[i] || "N/A";
             
             dataMap.set(docId, {
                docId,
                event: eventText,
                date: cleanDates[i],
                type: 'CALENDAR_EVENT'
             });
        }
        
        // Also save the raw lists just in case
        dataMap.set('CALENDAR_META', {
            docId: 'CALENDAR_META',
            allEvents: events,
            allDates: cleanDates,
            type: 'CALENDAR_META'
        });

    } else {
        // Fallback
        lines.forEach((l, i) => {
             dataMap.set(`LINE_${i}`, { docId: `LINE_${i}`, text: l, type: 'RAW_CALENDAR' });
        });
    }
}

const parseExam = (text, dataMap) => {
    // Handle multi-line format from OCR
    // Example Pattern:
    // ST
    // 21 April 2026
    // Sunday
    // 26 April 2026
    
    const lines = text.split('\n').map(l => l.trim()).filter(l => l);
    let idx = 0;

    // Regex for the class code (ST, MW, TR, SR) or full days
    const codeRegex = /^(ST|MW|TR|SR|Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday)$/i;
    // Regex for dates (e.g. 21 April 2026)
    const dateRegex = /^\d{1,2}\s+[A-Za-z]+\s+\d{4}$/;
    
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        
        if (codeRegex.test(line)) {
            // Found a potential start of a block
            // We look ahead for 3 more lines of data?
            // Structure: ClassDays -> LastClassDate -> ExamDay -> ExamDate
            
            // Check if we have enough lines ahead
            if (i+3 < lines.length) {
                const classDays = line;
                const next1 = lines[i+1];
                const next2 = lines[i+2];
                const next3 = lines[i+3];

                // Validation: Check if next1 is a date and next3 is a date
                // next2 should be a Day name
                
                if (dateRegex.test(next1) && dateRegex.test(next3)) {
                     const docId = `EXAM_${classDays.toUpperCase()}_${idx++}`;
                     dataMap.set(docId, {
                        docId,
                        classDays,
                        lastClassDate: next1,
                        examDay: next2,
                        examDate: next3,
                        type: 'EXAM_SCHEDULE'
                     });
                     
                     // Skip the lines we consumed
                     i += 3; 
                }
            }
        }
    }
}

const parsePdfText = (text, coursesMap, semesterId) => {
    if (!text) return;
    const lines = text.split('\n').map(l => l.trim()).filter(l => l);
    
    // Regex for Course Code (e.g., CSE101, ENG101, CSE 101)
    // Relaxed to allow optional space and potentially dashes
    const courseRegex = /^[A-Z]{3}\s?[-]?\s?\d{3}$/i;
    
    // Validation Regexes
    const facultyRegex = /^[A-Za-z\s\.]+$/;
    const capacityRegex = /^\d+\/\d+$/;

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        
        // Remove spaces for regex check if strictly looking for CSE101
        if (courseRegex.test(line)) {
            // Found potential course start
            // Look ahead to capture details
            // Expected Structure might vary.
            // 0: Code (CSE101)
            // 1: Section (1)
            // 2: Faculty (Must be Alphabet)
            // 3: Capacity (Num/Num)
            // 4: Timing (M 10:10 AM...)
            // 5: Room (529...)
            
            // If we are at the end, stop
            if (i + 5 >= lines.length) break;

            const code = line;
            const section = lines[i+1];
            let faculty = lines[i+2];
            let capacity = lines[i+3];
            let timingStr = lines[i+4];
            let room = lines[i+5];

            // --- Validation & Shift Logic ---
            // Sometimes OCR merges lines or splits them.
            
            // 1. Check if 'faculty' is actually capacity (numeric/slash)
            // Case: Missing Faculty
            if (capacityRegex.test(faculty) || /^\d+$/.test(faculty)) {
                 // Shift: Section -> Capacity -> Timing...
                 // Re-assign vars
                 capacity = faculty;
                 faculty = "TBA";
                 timingStr = lines[i+3];
                 room = lines[i+4];
                 // We consumed fewer lines, so we might need to adjust 'i' if we blindly jump?
                 // Current loop increments i by 1. We are just "peeking". We don't advance i artificially.
            } 
            // 2. Check if 'faculty' is Timing? (Starts with Day)
            else if (/^(Sun|Mon|Tue|Wed|Thu|Fri|Sat|S|M|T|W|R|F|A)/i.test(faculty) && /\d/.test(faculty)) {
                 timingStr = faculty;
                 faculty = "TBA";
                 capacity = "N/A";
                 room = lines[i+3];
            }

            processRowData(coursesMap, code, section, timingStr, code, faculty, room, capacity, semesterId); 
        }
    }
}

// Helper to extract text from Document AI cell
const getCellText = (cell, fullText) => {
    if (!cell.layout || !cell.layout.textAnchor || !cell.layout.textAnchor.textSegments) return "";
    
    return cell.layout.textAnchor.textSegments.map(segment => {
        const start = parseInt(segment.startIndex || "0");
        const end = parseInt(segment.endIndex);
        return fullText.substring(start, end);
    }).join("").replace(/\n/g, " "); // Replace newlines with spaces
}

// core logic shared between Excel and PDF parsers
const processRowData = (coursesMap, code, section, timingStr, courseName, faculty, room, capacity = "N/A", semesterId = "") => {
    const cleanCode = code ? code.replace(/\s+/g, '').toUpperCase() : "UNKNOWN";
    const cleanSection = section ? section.replace(/\s+/g, '').toUpperCase() : "1";
    
    // Namespaced ID to prevent cross-semester collisions
    const docId = semesterId ? `${semesterId}_${cleanCode}_${cleanSection}` : `${cleanCode}_${cleanSection}`;

    // Determine Dept
    let dept = "General";
    const c = cleanCode;
    if (c.startsWith("CSE") || c.startsWith("ICE")) dept = "Dept. of CSE";
    else if (['MAT', 'CHE', 'PHY', 'STA', 'DSA'].some(p => c.startsWith(p))) dept = "Dept. of MPS";
    else if (c.startsWith("ECO")) dept = "Dept. of Economics";
    else if (['BUS', 'ACT', 'ESR', 'FIN', 'HRM', 'ITB', 'MGT', 'MKT'].some(p => c.startsWith(p))) dept = "Dept. of BA";
    else if (c.startsWith("CE")) dept = "Dept. of Civil Engineering";
    else if (c.startsWith("ENG")) dept = "Dept. of English";

    // Parse Timing
    let dayRaw = "TBA";
    let startTime = "00:00";
    let endTime = "00:00";

    if (timingStr) {
        // Regex: ([SMTWRFA]+) followed by (Digits/Time)
        const match = timingStr.match(/^([SMTWRFA]+)\s+(.*)$/);
        if (match) {
            dayRaw = match[1].trim(); 
            const timeRange = match[2].trim();
            const parts = timeRange.replace(/–/g, '-').split('-');
            if (parts.length >= 2) {
                startTime = parts[0].trim();
                endTime = parts[1].trim();
            } else { startTime = timeRange; }
        } else {
            dayRaw = timingStr;
            // Fallback: If timingStr involves just Day (e.g. "Sunday")
        }
    }

    const dayMap = { 'S':'Sunday', 'M':'Monday', 'T':'Tuesday', 'W':'Wednesday', 'R':'Thursday', 'F':'Friday', 'A':'Saturday' };
    let days = [];
    // If dayRaw is like "Sunday", don't split it. Check if keys exist in dayRaw chars.
    for (let char of dayRaw.split('')) {
        if (dayMap[char]) days.push(dayMap[char]);
        else days.push(dayRaw); 
    }
    days = [...new Set(days)];


    if (!coursesMap.has(docId)) {
        coursesMap.set(docId, {
            docId, 
            code: cleanCode, // Explicitly save code
            section: cleanSection,
            semesterId,
            courseName, 
            dept, 
            faculty, 
            room, 
            capacity, // Added Capacity
            schedule: []
        });
    }

    const existingCourse = coursesMap.get(docId);
    for(let d of days) {
        existingCourse.schedule.push({ day: d, startTime, endTime });
    }
    // Update fields if we found better data in this row (e.g. duplicate rows for multi-day)
    if(faculty && faculty !== 'TBA') existingCourse.faculty = faculty;
    if(room && room !== 'TBA') existingCourse.room = room;
    if(capacity && capacity !== 'N/A') existingCourse.capacity = capacity;
}
