import psycopg2

def get_secret():
    try:
        conn = psycopg2.connect('postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres')
        cur = conn.cursor()
        cur.execute("SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'SUPA_SERVICE_ROLE_KEY' LIMIT 1")
        result = cur.fetchone()
        cur.close()
        conn.close()
        if result:
            return result[0]
        return None
    except Exception as e:
        print(f"Error: {e}")
        return None

if __name__ == "__main__":
    secret = get_secret()
    if secret:
        print(secret)
    else:
        print("NOT_FOUND")
