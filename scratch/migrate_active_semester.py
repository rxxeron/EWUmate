import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv(r'd:\EWUmate\EWUmate_Clean\ewumate_v2\.env')
sb = create_client(os.environ.get('SUPABASE_URL'), os.environ.get('SUPABASE_SERVICE_ROLE_KEY'))

print("--- Migrating Active Semester ---")
sql = """
ALTER TABLE active_semester 
ADD COLUMN IF NOT EXISTS is_advising_open BOOLEAN DEFAULT false;

ALTER TABLE active_semester 
ADD COLUMN IF NOT EXISTS is_next_semester_open BOOLEAN DEFAULT false;
"""

try:
    # Try using the exec_sql RPC if available, or just direct update if you have permission
    # Usually we use a direct update to a dummy record to test permissions first, 
    # but since this is DDL, we'll try the RPC.
    res = sb.rpc('exec_sql', {'sql_query': sql}).execute()
    print("Migration Successful:", res.data)
except Exception as e:
    print("RPC failed, trying direct table check...")
    # If RPC is not allowed, we can't do DDL via client easily.
    # But I will try to verify if the columns were added anyway (maybe previous command partially worked?)
    res = sb.table('active_semester').select('*').limit(1).execute()
    print("Current Columns:", res.data[0].keys() if res.data else "No data")
