import postgres from 'https://deno.land/x/postgresjs@v3.3.4/mod.js'

const SUPABASE_DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

const sqlQuery = `
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'calendar_spring2026'
  OR table_name = 'calendar_Spring2026'
ORDER BY ordinal_position;
`;

async function main() {
    try {
        const sql = postgres(SUPABASE_DB_URL, { max: 1 })
        const result = await sql.unsafe(sqlQuery)
        console.log(JSON.stringify(result, null, 2))
        await sql.end()
    } catch (err) {
        console.error("Error:", err.message)
    }
}

main()
