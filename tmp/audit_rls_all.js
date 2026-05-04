const { createClient } = require('@supabase/supabase-client');
require('dotenv').config({ path: 'admin_panel/.env' });

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_ANON_KEY
);

async function checkAllPolicies() {
  const tables = [
    'course_metadata',
    'scholarship_policies',
    'grade_scale',
    'active_semester',
    'semesters',
    'notifications'
  ];

  console.log('--- RLS Policy Audit ---');

  for (const table of tables) {
    const { data: policies, error } = await supabase.rpc('get_policies_for_table', { t_name: table });
    
    if (error) {
       // If RPC doesn't exist, try a direct query to pg_policies (might fail with anon key)
       console.log(`Table ${table}: Could not fetch policies via RPC. Trying manual query...`);
       const { data, error: pgError } = await supabase
        .from('pg_policies')
        .select('*')
        .eq('tablename', table);
        
       if (pgError) {
         console.log(`Table ${table}: Error checking policies: ${pgError.message}`);
       } else {
         console.log(`Table ${table} policies:`, data);
       }
    } else {
      console.log(`Table ${table} policies:`, policies);
    }
  }
}

// Since we can't easily query pg_policies with anon key unless an RPC is exposed,
// let's try to do a test update on a non-existent row to see if it triggers an RLS error vs 0 rows error.
async function testUpdates() {
  const tables = [
    { name: 'course_metadata', pk: 'code', val: 'NON_EXISTENT_TEST' },
    { name: 'grade_scale', pk: 'grade', val: 'X_TEST' }
  ];

  for (const table of tables) {
    console.log(`\nTesting UPDATE on ${table.name}...`);
    const { data, error, status } = await supabase
      .from(table.name)
      .update({ name: 'Test' })
      .eq(table.pk, table.val);
      
    console.log(`Status: ${status}`);
    if (error) {
      console.log(`Error: ${error.code} - ${error.message}`);
    } else {
      console.log(`Success (or 0 rows affected).`);
    }
  }
}

checkAllPolicies().then(() => testUpdates());
