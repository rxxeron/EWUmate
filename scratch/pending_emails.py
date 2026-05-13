import psycopg2

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def get_pending_emails():
    try:
        conn = psycopg2.connect(conn_url)
        cur = conn.cursor()
        
        print("\n--- Emails of Pending Registrations (Older Batches) ---")
        
        cur.execute("""
            SELECT u.email, p.full_name, p.student_id, p.onboarding_status, u.created_at
            FROM auth.users u
            JOIN public.profiles p ON u.id = p.id
            WHERE p.onboarding_status != 'completed'
            AND NOT (
                p.student_id LIKE '2026-2%' 
                OR p.admitted_semester ILIKE '%2026-2%' 
                OR p.admitted_semester ILIKE '%Summer 2026%'
            )
            ORDER BY u.created_at DESC;
        """)
        pending = cur.fetchall()
        
        for email, name, sid, status, created in pending:
            print(f"Email: {email} | Name: {name or 'N/A'} | ID: {sid or 'N/A'} | Status: {status} | Joined: {created}")

        print(f"\nTotal Pending Emails: {len(pending)}")

        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Database Error: {e}")

if __name__ == "__main__":
    get_pending_emails()
