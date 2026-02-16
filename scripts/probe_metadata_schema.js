const { createClient } = require('@supabase/supabase-js');

const PROJECT_REF = 'jwygjihrbwxhehijldiz';
const SUPABASE_URL = `https://${PROJECT_REF}.supabase.co`;
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function inspectSchema() {
    console.log("🔍 Inspecting 'metadata' table columns via RPC/REST...");

    // We can't easily query information_schema via REST unless there's a view.
    // But we can try to insert a dummy row to see what happens.
    const { data, error } = await supabase
        .from('metadata')
        .insert({ id: 'test_probe', data: {} })
        .select();

    if (error) {
        console.error("❌ Probe Error:", error.message);
        console.error("Details:", error.details);
    } else {
        console.log("✅ Probe Success! Current Columns:", Object.keys(data[0]));
        // Delete probe
        await supabase.from('metadata').delete().eq('id', 'test_probe');
    }
}

inspectSchema();
