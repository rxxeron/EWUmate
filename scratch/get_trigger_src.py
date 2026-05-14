import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.environ.get("DATABASE_URL"))
cur = conn.cursor()

cur.execute("SELECT prosrc FROM pg_proc WHERE proname = 'handle_scraper_log_trigger'")
row = cur.fetchone()
if row:
    print(row[0])
else:
    print("Function not found.")

cur.close()
conn.close()
