const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://jwygjihrbwxhehijldiz.supabase.co';
const supabaseKey = 'REDACTED_SUPABASE_SERVICE_ROLE_KEY';

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
