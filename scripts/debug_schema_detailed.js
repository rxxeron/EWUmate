const { createClient } = require('@supabase/supabase-js');

const PROJECT_REF = 'jwygjihrbwxhehijldiz';
const SUPABASE_URL = `https://${PROJECT_REF}.supabase.co`;
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function debugSchema() {
    console.log("🔍 Debugging Database Schema...");

    // Check if we can run a raw query via a trick (selecting from a non-existent table sometimes gives hints)
    // But better: try to call a system table
    const { data, error } = await supabase
        .from('metadata')
        .select('id')
        .limit(1);

    if (error) {
        console.error("❌ Error accessing 'metadata':", error.message);
        console.error("Code:", error.code);
        console.error("Hint:", error.hint);
        console.error("Details:", error.details);
    } else {
        console.log("✅ Success! 'id' column found.");
    }
}

debugSchema();
