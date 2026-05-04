import psycopg2
import json

db_url = 'postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres'
conn = psycopg2.connect(db_url)
try:
    curr = conn.cursor()
    val = json.dumps({'update_available': True, 'download_url': 'https://github.com/rxxeron/ewumate_app/releases'})
    curr.execute("INSERT INTO app_config (key, value) VALUES ('update_info', %s) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;", (val,))
    conn.commit()
    print('Inserted update_info safely.')
except Exception as e:
    print('Error:', e)
finally:
    conn.close()
