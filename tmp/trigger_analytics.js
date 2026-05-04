const { Client } = require('pg');

async function triggerAnalytics() {
    const client = new Client({
        connectionString: "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"
    });

    try {
        await client.connect();
        await client.query(`
            UPDATE semester_course_marks 
            SET grade_goal = grade_goal 
            WHERE user_id = '374a09cd-c366-4eea-89cc-dbda99154c3e'
            AND semester_code = 'Spring2026';
        `);
        console.log('Analytics trigger fired successfully for all marks!');
    } catch (err) {
        console.error('Error triggering analytics:', err);
    } finally {
        await client.end();
    }
}

triggerAnalytics();
