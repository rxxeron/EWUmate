const { Client } = require('pg');

async function checkMetadata() {
    const client = new Client({
        connectionString: "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"
    });

    try {
        await client.connect();
        const res = await client.query("SELECT count(*) FROM course_metadata");
        console.log('Total metadata entries:', res.rows[0].count);
        
        const sample = await client.query("SELECT code, name FROM course_metadata LIMIT 5");
        console.log('Sample courses:', sample.rows);
    } catch (err) {
        console.error('Error:', err);
    } finally {
        await client.end();
    }
}

checkMetadata();
