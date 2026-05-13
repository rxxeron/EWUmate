import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

sb = create_client(os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY"))

sql = "NOTIFY pgrst, 'reload schema';"
print("Reloading PostgREST schema cache...")
try:
    sb.rpc("exec_sql", {"sql_query": sql}).execute()
    print("Success!")
except Exception as e:
    print(f"Error: {e}")
