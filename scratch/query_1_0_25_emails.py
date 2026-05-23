import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def fetch_1_0_25_emails():
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    try:
        cur.execute("""
            SELECT auth.users.email, public.profiles.app_version
            FROM public.profiles
            JOIN auth.users ON public.profiles.id = auth.users.id
            WHERE public.profiles.app_version IN ('1.0.25', 'v1.0.25')
              AND auth.users.email IS NOT NULL;
        """)
        rows = cur.fetchall()
        
        emails = sorted(list(set(row[0].strip() for row in rows)))
        comma_separated = ", ".join(emails)
        
        print(f"Total unique users on version 1.0.25: {len(emails)}")
        print("\n--- Emails ---")
        print(comma_separated)
        
        # Save to scratch directory
        with open("scratch/emails_1_0_25.txt", "w") as f:
            f.write(comma_separated)
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    fetch_1_0_25_emails()
