import psycopg2
import psycopg2.extras
from dotenv import load_dotenv
import os
import json
from datetime import datetime

load_dotenv()
conn = psycopg2.connect(os.environ.get('DATABASE_URL'))
cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

backup = {
    'generated_at': datetime.now().isoformat(),
    'tables': {},
    'functions': [],
    'policies': [],
    'triggers': []
}

# 1. Tables and Columns
cur.execute("""
    SELECT table_name, column_name, data_type, is_nullable, column_default
    FROM information_schema.columns
    WHERE table_schema = 'public'
""")
for row in cur.fetchall():
    t_name = row['table_name']
    if t_name not in backup['tables']:
        backup['tables'][t_name] = []
    backup['tables'][t_name].append({
        'column': row['column_name'],
        'type': row['data_type'],
        'nullable': row['is_nullable'],
        'default': row['column_default']
    })

# 2. Functions
cur.execute("""
    SELECT proname as function_name, pg_get_functiondef(oid) as definition
    FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
""")
for row in cur.fetchall():
    backup['functions'].append({
        'name': row['function_name'],
        'def': row['definition']
    })

# 3. RLS Policies
cur.execute("""
    SELECT policyname, tablename, roles, cmd, qual, with_check
    FROM pg_policies
    WHERE schemaname = 'public'
""")
backup['policies'] = cur.fetchall()

# 4. Triggers
cur.execute("""
    SELECT event_object_table as table, trigger_name, action_statement
    FROM information_schema.triggers
    WHERE trigger_schema = 'public'
""")
backup['triggers'] = cur.fetchall()

# 5. pg_cron (if available)
try:
    cur.execute("SELECT jobid, schedule, command, nodename, active FROM cron.job")
    backup['cron_jobs'] = cur.fetchall()
except Exception:
    conn.rollback()
    backup['cron_jobs'] = "cron extension not accessible or empty"

with open('schema_backup.json', 'w') as f:
    json.dump(backup, f, indent=2, default=str)

print(f"Successfully exported {len(backup['tables'])} tables, {len(backup['functions'])} functions, {len(backup['policies'])} RLS policies, and {len(backup['triggers'])} triggers to schema_backup.json")
