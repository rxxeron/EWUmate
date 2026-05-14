import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.environ.get("DATABASE_URL"))
cur = conn.cursor()

service_role_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

if not service_role_key:
    print("Error: SUPABASE_SERVICE_ROLE_KEY not found in .env")
    exit(1)

try:
    # 1. Check if it already exists
    cur.execute("SELECT id FROM vault.decrypted_secrets WHERE name = 'SUPA_SERVICE_ROLE_KEY'")
    if cur.fetchone():
        print("Key SUPA_SERVICE_ROLE_KEY already exists. Updating...")
        # Update using a vaulted secret approach is complex, easier to delete and re-insert if permitted
        cur.execute("DELETE FROM vault.secrets WHERE name = 'SUPA_SERVICE_ROLE_KEY'")
    
    # 2. Insert new secret
    # Note: Use the vault.secrets table and the vault.create_secret function if available, 
    # but direct insert into vault.secrets is often blocked. 
    # Standard way in Supabase:
    sql = f"SELECT vault.create_secret('{service_role_key}', 'SUPA_SERVICE_ROLE_KEY', 'Service Role Key for Edge Functions')"
    cur.execute(sql)
    
    conn.commit()
    print("Successfully added SUPA_SERVICE_ROLE_KEY to the vault.")
except Exception as e:
    conn.rollback()
    print(f"Error adding secret to vault: {e}")

cur.close()
conn.close()
