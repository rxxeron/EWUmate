
import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

res = supabase.from_("profiles").select("app_version").not_.is_("app_version", "null").execute()
versions = sorted(list(set([r['app_version'] for r in res.data])))
print("Available Versions:")
for v in versions:
    print(f"- {v}")
