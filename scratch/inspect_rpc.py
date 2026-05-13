import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

sb = create_client(os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY"))

sql = """
SELECT prosrc 
FROM pg_proc 
JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace 
WHERE proname = 'create_course_table';
"""

print("Fetching 'create_course_table' definition...")
try:
    res = sb.rpc("exec_sql", {"sql_query": sql}).execute()
    if res.data:
        print(res.data[0]['prosrc'])
    else:
        print("Function not found.")
except Exception as e:
    print(f"Error: {e}")
