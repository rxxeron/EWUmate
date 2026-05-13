import os
from supabase import create_client
from dotenv import load_dotenv
import json

load_dotenv()

sb = create_client(os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY"))

sql = "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE 'faculty%';"
res = sb.rpc("exec_sql", {"sql_query": sql}).execute()
print(json.dumps(res.data, indent=2))
