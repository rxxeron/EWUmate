import psycopg2
import csv

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def get_2026_2_pending():
    try:
        conn = psycopg2.connect(conn_url)
        cur = conn.cursor()
        
        print("\n--- Pending Registrations (2026-2 Intake) ---")
        
        query = """
            SELECT u.email, p.full_name, p.student_id, p.onboarding_status, u.created_at
            FROM auth.users u
            JOIN public.profiles p ON u.id = p.id
            WHERE p.onboarding_status != 'completed'
            AND (
                p.student_id LIKE '2026-2%' 
                OR p.admitted_semester ILIKE '%2026-2%' 
                OR p.admitted_semester ILIKE '%Summer 2026%'
            )
            ORDER BY u.created_at DESC;
        """
        cur.execute(query)
        pending = cur.fetchall()
        
        for email, name, sid, status, created in pending:
            print(email)

        print(f"\nTotal Pending (2026-2): {len(pending)}")

        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Database Error: {e}")

if __name__ == "__main__":
    get_2026_2_pending()
