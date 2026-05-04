const { Client } = require('pg');

async function viewMarks() {
    const client = new Client({
        connectionString: "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"
    });

    try {
        await client.connect();
        const res = await client.query(`
            SELECT semester_code, course_code, marks 
            FROM semester_course_marks 
            WHERE user_id = '374a09cd-c366-4eea-89cc-dbda99154c3e'
        `);
        console.log('Total Marks Found:', res.rows.length);
        console.log(JSON.stringify(res.rows, null, 2));
    } catch (err) {
        console.error('Error:', err);
    } finally {
        await client.end();
    }
}

viewMarks();
