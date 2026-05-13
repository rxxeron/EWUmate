import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

sb = create_client(os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY"))

table = "courses_summer2026"
sql = f"ALTER TABLE public.{table} ADD COLUMN faculty_full_name TEXT;"

print(f"Executing SQL for {table}...")
try:
    res = sb.rpc("exec_sql", {"sql_query": sql}).execute()
    print("Success!")
except Exception as e:
    print(f"Error: {e}")
