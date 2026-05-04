const { Client } = require('pg');

async function runQuery() {
    const sql = process.argv[2];
    if (!sql) {
        console.error('Please provide SQL query as argument');
        process.exit(1);
    }

    const client = new Client({
        connectionString: "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"
    });

    try {
        await client.connect();
        const res = await client.query(sql);
        console.log(JSON.stringify(res.rows, null, 2));
    } catch (err) {
        console.error('Error executing query:', err);
    } finally {
        await client.end();
    }
}

runQuery();
