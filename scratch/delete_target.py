import psycopg2

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def delete_specific_user(email):
    try:
        conn = psycopg2.connect(conn_url)
        cur = conn.cursor()
        
        cur.execute(f"SELECT id FROM auth.users WHERE email = '{email}';")
        res = cur.fetchone()
        
        if not res:
            print(f"User with email {email} not found in auth.users.")
            return
            
        user_id = res[0]
        print(f"Found user {email} with ID: {user_id}")
        
        try:
            cur.execute(f"DELETE FROM auth.users WHERE id = '{user_id}';")
            conn.commit()
            print(f"SUCCESS: User {email} deleted successfully.")
        except Exception as e:
            print(f"FAILED to delete {email}: {e}")
            conn.rollback()

        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Database Error: {e}")

if __name__ == "__main__":
    delete_specific_user('tester46@gmail.com')
