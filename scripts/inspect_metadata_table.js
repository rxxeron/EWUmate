const { createClient } = require('@supabase/supabase-js');

const PROJECT_REF = 'jwygjihrbwxhehijldiz';
const SUPABASE_URL = `https://${PROJECT_REF}.supabase.co`;
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function inspect() {
    console.log("Checking metadata table...");
    const { data, error } = await supabase.rpc('get_table_info', { t_name: 'metadata' });

    // Fallback: just try to select
    const { data: selectData, error: selectError } = await supabase.from('metadata').select('*').limit(1);

    if (selectError) {
        console.error("Select error:", selectError.message);
    } else {
        console.log("Columns found:", Object.keys(selectData[0] || {}));
    }
}

inspect();
