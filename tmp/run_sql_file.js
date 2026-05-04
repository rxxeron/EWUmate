const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

async function runFix() {
    const filePath = process.argv[2];
    if (!filePath) {
        console.error('Please provide SQL file path as argument');
        process.exit(1);
    }

    const client = new Client({
        connectionString: "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"
    });

    try {
        await client.connect();
        const fullPath = path.isAbsolute(filePath) ? filePath : path.join(process.cwd(), filePath);
        const sql = fs.readFileSync(fullPath, 'utf8');
        console.log(`Executing SQL from ${fullPath}...`);
        await client.query(sql);
        console.log('SQL executed successfully!');
    } catch (err) {
        console.error('Error executing SQL:', err);
    } finally {
        await client.end();
    }
}

runFix();
