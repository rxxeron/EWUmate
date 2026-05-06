
import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") # Use service role for admin queries
supabase: Client = create_client(url, key)

def check_exhaustion():
    print("Checking Database Activity...")
    try:
        # Check active connections and long-running queries
        # Note: We might not have permission to select from pg_stat_activity directly via API
        # unless we use a custom RPC or the service role has access.
        # Let's try a simple health check first.
        res = supabase.table("profiles").select("count", count="exact").limit(1).execute()
        print(f"Health Check: Successfully connected. Total profiles: {res.count}")
        
        # Check if triggers are actually optimized
        # We can't easily check trigger state via select, but we can check the 'profiles' table for recent updates
        # if there are thousands of updates per second, it means something is still thrashing.
        res_recent = supabase.table("profiles").select("updated_at").order("updated_at", ascending=False).limit(5).execute()
        print("\nLatest Profile Updates (UTC):")
        for p in res_recent.data:
            print(f"- {p['updated_at']}")

    except Exception as e:
        print(f"Error checking DB: {e}")

if __name__ == "__main__":
    check_exhaustion()
