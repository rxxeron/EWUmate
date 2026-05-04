const { Client } = require('pg');

async function checkRLS() {
    const client = new Client({
        connectionString: "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"
    });

    try {
        await client.connect();
        
        // 1. Check if table exists
        const tableCheck = await client.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_name = 'feedback_comments';
        `);
        console.log('Table exists:', tableCheck.rows.length > 0);

        // 2. Check existing policies
        const policyCheck = await client.query(`
            SELECT * FROM pg_policies WHERE tablename = 'feedback_comments';
        `);
        console.log('Existing Policies:', policyCheck.rows);

        // 3. Check RLS status
        const rlsCheck = await client.query(`
            SELECT relrowsecurity FROM pg_class WHERE relname = 'feedback_comments';
        `);
        console.log('RLS Enabled:', rlsCheck.rows[0]?.relrowsecurity);

    } catch (err) {
        console.error('Error checking RLS:', err);
    } finally {
        await client.end();
    }
}

checkRLS();
