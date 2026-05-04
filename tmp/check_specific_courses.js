const { Client } = require('pg');

async function checkSpecificCourses() {
    const client = new Client({
        connectionString: "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"
    });

    try {
        await client.connect();
        const res = await client.query("SELECT code, name FROM course_metadata WHERE code IN ('CHE109', 'ICE107', 'ICE204', 'MAT102')");
        console.log('Courses Found:', res.rows);
    } catch (err) {
        console.error('Error:', err);
    } finally {
        await client.end();
    }
}

checkSpecificCourses();
