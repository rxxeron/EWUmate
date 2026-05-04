const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://jwygjihrbwxhehijldiz.supabase.co';
const supabaseKey = 'REDACTED_SUPABASE_SERVICE_ROLE_KEY';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkLiveSchema() {
  console.log('--- CHECKING LIVE DB SCHEMA ---');
  
  // Check foreign keys for profiles table
  const { data: fks, error: fkError } = await supabase
    .rpc('get_table_constraints', { t_name: 'profiles' });

  if (fkError) {
    // If RPC doesn't exist, try a direct query on information_schema (might be blocked by RLS even for service_role)
    console.log('RPC get_table_constraints not found, trying direct select...');
    const { data: directData, error: directError } = await supabase
      .from('profiles')
      .select('id')
      .limit(1);
    
    if (directError) {
      console.error('Error accessing profiles:', directError);
    } else {
      console.log('Successfully accessed profiles table.');
    }
  } else {
    console.log('Constraints for profiles:', fks);
  }

  // Check all tables
  const { data: tables, error: tableError } = await supabase
    .from('profiles') // Just to check connectivity
    .select('*')
    .limit(1);

  if (tableError) {
    console.error('Table error:', tableError);
  } else {
    console.log('Connectivity OK.');
  }
}

checkLiveSchema();
