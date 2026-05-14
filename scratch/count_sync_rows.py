import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(url, key)

response = supabase.table("user_semester_states").select("count", count="exact").eq("updated_at", "2026-05-14T19:52:15.684+00:00").execute()
print(f"Rows updated at 19:52:15: {response.count}")
