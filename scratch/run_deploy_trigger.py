import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.environ.get("DATABASE_URL"))
cur = conn.cursor()

with open("scratch/deploy_trigger_v2.sql", "r") as f:
    sql = f.read()

try:
    cur.execute(sql)
    conn.commit()
    print("Successfully deployed trigger v2.")
except Exception as e:
    conn.rollback()
    print(f"Error deploying trigger: {e}")

cur.close()
conn.close()
