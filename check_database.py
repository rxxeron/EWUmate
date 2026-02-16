import requests
import json

# Supabase credentials
SUPABASE_URL = "https://vcfijikafkofgakxnbib.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZjZmlqaWthZmtvZmdha3huYmliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc1NzY2NjQsImV4cCI6MjA1MzE1MjY2NH0.XcPMCZ69YpXojrfN2M0V0K9w4L5HYdJMpLHU6A3QX0k"

def check_tables():
    """Check what tables exist in the database"""
    print("🔍 Checking existing tables...\n")
    
    # Query to get all tables
    query = """
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public'
    ORDER BY table_name;
    """
    
    response = requests.post(
        f"{SUPABASE_URL}/rest/v1/rpc/query",
        headers={
            "apikey": SUPABASE_ANON_KEY,
            "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
            "Content-Type": "application/json"
        },
        json={"query": query}
    )
    
    if response.status_code == 200:
        print("✅ Tables in database:")
        print(json.dumps(response.json(), indent=2))
    else:
        print(f"❌ Error: {response.status_code}")
        print(response.text)

def check_config():
    """Check config table"""
    print("\n🔍 Checking config table...\n")
    
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/config?select=*",
        headers={
            "apikey": SUPABASE_ANON_KEY,
            "Authorization": f"Bearer {SUPABASE_ANON_KEY}"
        }
    )
    
    if response.status_code == 200:
        data = response.json()
        if data:
            print("✅ Config data:")
            print(json.dumps(data, indent=2))
        else:
            print("⚠️ Config table is empty")
    else:
        print(f"❌ Error: {response.status_code}")
        print(response.text)

def check_courses():
    """Check if courses table exists and has data"""
    print("\n🔍 Checking courses_Spring2026 table...\n")
    
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/courses_Spring2026?select=count",
        headers={
            "apikey": SUPABASE_ANON_KEY,
            "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
            "Prefer": "count=exact"
        }
    )
    
    if response.status_code == 200:
        count = response.headers.get('Content-Range', '0').split('/')[-1]
        print(f"✅ courses_Spring2026 exists with {count} records")
        
        # Get first 5 records
        response2 = requests.get(
            f"{SUPABASE_URL}/rest/v1/courses_Spring2026?select=*&limit=5",
            headers={
                "apikey": SUPABASE_ANON_KEY,
                "Authorization": f"Bearer {SUPABASE_ANON_KEY}"
            }
        )
        if response2.status_code == 200:
            print("\nSample records:")
            print(json.dumps(response2.json(), indent=2))
    elif response.status_code == 404:
        print("❌ Table courses_Spring2026 does not exist!")
    else:
        print(f"❌ Error: {response.status_code}")
        print(response.text)

if __name__ == "__main__":
    print("=" * 60)
    print("SUPABASE DATABASE CHECKER")
    print("=" * 60)
    
    check_config()
    check_courses()
    
    print("\n" + "=" * 60)
    print("\n💡 To create missing tables, run this SQL in Supabase:")
    print("   Dashboard → SQL Editor → Run: supabase/migrations/20260215_create_tables.sql")
    print("\n💡 To check Edge Function logs:")
    print("   Dashboard → Edge Functions → pdf-parser → Logs")
    print("=" * 60)
