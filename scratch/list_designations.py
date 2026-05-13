import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

sb = create_client(os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY"))

res = sb.table("faculty_master").select("designation_name").execute()
unique_ids = sorted(list(set([r['designation_name'] for r in res.data if r['designation_name']])))
print(f"Unique Designation IDs found: {unique_ids}")
