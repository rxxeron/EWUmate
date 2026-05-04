const { Client } = require('pg');
const fs = require('fs');

async function runFix() {
    const client = new Client({
        connectionString: "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"
    });

    try {
        await client.connect();
        const sql = fs.readFileSync('C:\\Users\\Farzana Safa\\.gemini\\antigravity\\brain\\99e5e43c-841d-4650-bd67-0de1146d3821\\master_fix.sql', 'utf8');
        await client.query(sql);
        console.log('Master fix applied successfully!');
    } catch (err) {
        console.error('Error applying fix:', err);
    } finally {
        await client.end();
    }
}

runFix();
