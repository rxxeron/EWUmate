import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.environ.get("DATABASE_URL"))
cur = conn.cursor()

try:
    cur.execute("SELECT name FROM vault.decrypted_secrets")
    rows = cur.fetchall()
    for row in rows:
        print(row[0])
except Exception as e:
    print(f"Error checking vault: {e}")

cur.close()
conn.close()
