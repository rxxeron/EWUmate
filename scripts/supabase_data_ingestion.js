const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

// Config
const PROJECT_REF = 'jwygjihrbwxhehijldiz';
const SUPABASE_URL = `https://${PROJECT_REF}.supabase.co`;
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

/**
 * Uploads course schedule for a specific semester.
 * Replaces existing data for the same semester/code/section.
 */
async function uploadSemesterCourses(jsonPath, semesterCode) {
    console.log(`\n📚 Uploading courses for ${semesterCode}...`);

    if (!fs.existsSync(jsonPath)) {
        console.error(`❌ File not found: ${jsonPath}`);
        return;
    }

    const rawData = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
    console.log(`   Found ${rawData.length} courses in JSON.`);

    // Mapping to Supabase Schema
    const rows = rawData.map(c => {
        // Construct a unique doc_id if not present to ensure replacement
        const docId = c.doc_id || `${semesterCode}_${c.courseCode}_${c.section}`.replace(/\s+/g, '');

        return {
            doc_id: docId,
            semester: semesterCode,
            code: (c.courseCode || c.code).toUpperCase().replace(/\s+/g, ''),
            section: c.section.toString(),
            course_name: c.courseName || c.name || c.courseCode,
            credits: parseFloat(c.credits || 3.0),
            capacity: c.capacity || "0/0",
            type: c.type || (c.day?.includes('Lab') ? 'Lab' : 'Theory'),
            sessions: c.sessions || [
                {
                    day: c.day,
                    start_time: c.startTime,
                    end_time: c.endTime,
                    room: c.room
                }
            ]
        };
    });

    // Batch upsert (chunks of 100)
    for (let i = 0; i < rows.length; i += 100) {
        const chunk = rows.slice(i, i + 100);
        const { error } = await supabase.from('courses').upsert(chunk, { onConflict: 'doc_id' });
        if (error) {
            console.error(`   ❌ Error in chunk ${i / 100}:`, error.message);
        } else {
            console.log(`   ✅ Uploaded chunk ${i / 100 + 1}`);
        }
    }

    console.log(`🎉 Finished uploading courses for ${semesterCode}.`);
}

/**
 * Updates the master catalog in course_metadata.
 */
async function updateCourseMetadata(jsonPath) {
    console.log(`\n📦 Updating Master Catalog (course_metadata)...`);

    if (!fs.existsSync(jsonPath)) {
        console.error(`❌ File not found: ${jsonPath}`);
        return;
    }

    const rawData = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

    // Extract unique course codes to avoid bloat
    const unique = new Map();
    rawData.forEach(c => {
        const code = (c.courseCode || c.code).toUpperCase().replace(/\s+/g, '');
        if (!unique.has(code)) {
            unique.set(code, {
                code: code,
                name: c.courseName || c.name || c.courseCode,
                credits: parseFloat(c.credits || 3.0),
                credit_val: parseFloat(c.credits || 3.0)
            });
        }
    });

    const rows = Array.from(unique.values());
    console.log(`   Processed ${rows.length} unique courses for catalog.`);

    const { error } = await supabase.from('course_metadata').upsert(rows, { onConflict: 'code' });
    if (error) console.error("   ❌ Error updating metadata:", error.message);
    else console.log("   ✅ Master catalog updated.");
}

/**
 * Sets the current active semester in config.
 */
async function setCurrentSemester(semesterCode) {
    console.log(`\n⚙️ Setting current semester to: ${semesterCode}`);
    const { error } = await supabase.from('config').upsert({ key: 'currentSemester', value: semesterCode });
    if (error) console.error("   ❌ Error setting config:", error.message);
    else console.log("   ✅ Config updated.");
}

// Example usage (uncomment and modify paths as needed)
async function main() {
    const coursesJson = './scripts/courses_spring2026.json'; // Path to your extracted data
    const semester = 'Spring2026';

    // await updateCourseMetadata(coursesJson); // Update catalog from the new list too
    // await uploadSemesterCourses(coursesJson, semester);
    // await setCurrentSemester(semester);
}

// Export for use or run directly
module.exports = { uploadSemesterCourses, updateCourseMetadata, setCurrentSemester };

if (require.main === module) {
    main();
}
