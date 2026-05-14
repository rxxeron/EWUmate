import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(url, key)

response = supabase.table("parsing_logs").select("*").order("created_at", desc=True).execute()
for row in response.data:
    print(row)
