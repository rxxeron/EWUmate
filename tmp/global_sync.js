const { Client } = require('pg');

async function triggerGlobalSync() {
    const client = new Client({
        connectionString: "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"
    });

    try {
        await client.connect();
        console.log('Starting Global Sync...');

        // 1. Trigger History Sync for everyone
        console.log('Syncing History (Completed Courses)...');
        await client.query(`UPDATE completed_courses SET credits = credits;`);

        // 2. Trigger Projection Sync for everyone
        console.log('Syncing Projections (Course Marks)...');
        await client.query(`UPDATE semester_course_marks SET grade_goal = grade_goal;`);

        // 3. Trigger Profile-to-Analytics Sync for everyone
        console.log('Syncing Profiles...');
        await client.query(`UPDATE profiles SET total_credits_earned = total_credits_earned;`);

        console.log('Global Sync completed successfully for all users! 🚀');
    } catch (err) {
        console.error('Global Sync failed:', err);
    } finally {
        await client.end();
    }
}

triggerGlobalSync();
