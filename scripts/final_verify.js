const { createClient } = require('@supabase/supabase-js');

const PROJECT_REF = 'jwygjihrbwxhehijldiz';
const SUPABASE_URL = `https://${PROJECT_REF}.supabase.co`;
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function verify() {
    console.log("🏁 FINAL VERIFICATION...");

    const tables = [
        'profiles', 'course_metadata', 'metadata', 'courses', 'calendar',
        'academic_data', 'user_schedules', 'semester_progress'
    ];

    for (const table of tables) {
        const { count, error } = await supabase
            .from(table)
            .select('*', { count: 'exact', head: true });

        if (error) {
            console.error(`❌ ${table}: ${error.message}`);
        } else {
            console.log(`✅ ${table}: ${count} rows found.`);
        }
    }
}

verify();
