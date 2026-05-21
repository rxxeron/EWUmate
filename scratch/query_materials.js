const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://jwygjihrbwxhehijldiz.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';

const supabase = createClient(supabaseUrl, supabaseKey);

async function listMaterials() {
  const { data, error } = await supabase.from('study_materials').select('*');
  if (error) {
    console.error('Error fetching materials:', error);
  } else {
    console.log('Study Materials in DB:');
    console.log(JSON.stringify(data, null, 2));
  }
}

listMaterials();
