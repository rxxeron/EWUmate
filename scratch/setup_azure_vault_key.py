import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.environ.get("DATABASE_URL"))
cur = conn.cursor()

azure_key = os.environ.get("AZURE_FUNCTION_KEY")

if not azure_key:
    print("Error: AZURE_FUNCTION_KEY not found in .env")
    exit(1)

try:
    # Delete if exists
    cur.execute("DELETE FROM vault.secrets WHERE name = 'AZURE_FUNCTION_KEY'")
    
    # Insert new secret
    sql = f"SELECT vault.create_secret('{azure_key}', 'AZURE_FUNCTION_KEY', 'Azure Function Key for Snapshots')"
    cur.execute(sql)
    
    conn.commit()
    print("Successfully added AZURE_FUNCTION_KEY to the vault.")
except Exception as e:
    conn.rollback()
    print(f"Error adding secret to vault: {e}")

cur.close()
conn.close()
