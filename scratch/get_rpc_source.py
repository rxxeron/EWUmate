import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

sb = create_client(os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY"))

sql = """
SELECT pg_get_functiondef(p.oid)
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = 'create_course_table';
"""

print("Fetching 'create_course_table' source code...")
try:
    res = sb.rpc("exec_sql", {"sql_query": sql}).execute()
    if res.data:
        print(res.data[0]['pg_get_functiondef'])
    else:
        print("Function not found in 'public' schema.")
except Exception as e:
    print(f"Error: {e}")
