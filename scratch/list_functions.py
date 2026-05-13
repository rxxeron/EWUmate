import os
from supabase import create_client
from dotenv import load_dotenv
import json

load_dotenv()

sb = create_client(os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY"))

sql = "SELECT proname FROM pg_proc JOIN pg_namespace n ON n.oid = pg_proc.pronamespace WHERE n.nspname = 'public';"
print("Listing functions...")
try:
    res = sb.rpc("exec_sql", {"sql_query": sql}).execute()
    print(json.dumps([r['proname'] for r in res.data], indent=2))
except Exception as e:
    print(f"Error: {e}")
