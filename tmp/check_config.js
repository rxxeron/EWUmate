const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://jwygjihrbwxhehijldiz.supabase.co';
const supabaseKey = 'dummy'; // I don't have the service key handy, but I have the postgres string

const { Client } = require('pg');

async function checkConfig() {
  const client = new Client({
    connectionString: "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"
  });

  try {
    await client.connect();
    const res = await client.query('SELECT * FROM app_config;');
    console.log(JSON.stringify(res.rows, null, 2));
  } catch (err) {
    console.error('Database connection error:', err.stack);
  } finally {
    await client.end();
  }
}

checkConfig();
