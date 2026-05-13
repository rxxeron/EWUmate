import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

sb = create_client(os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY"))

ids = ['140', '141', '142', '143', '147', '148', '152', '155', '18', '96']
for d_id in ids:
    res = sb.table("faculty_master").select("full_name").eq("designation_name", d_id).limit(2).execute()
    names = [r['full_name'] for r in res.data]
    print(f"ID {d_id}: {names}")
