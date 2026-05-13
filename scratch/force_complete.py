import psycopg2

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def force_complete_onboarding():
    try:
        conn = psycopg2.connect(conn_url)
        cur = conn.cursor()
        
        print("\n--- Force Completing Onboarding for Mismatched Users ---")
        
        # Identify users first
        cur.execute("""
            SELECT DISTINCT p.id, p.student_id
            FROM public.profiles p
            JOIN public.enrollments e ON p.id = e.user_id
            WHERE p.onboarding_status = 'course_history';
        """)
        users = cur.fetchall()
        
        if not users:
            print("No mismatched users found.")
            return

        uids = [u[0] for u in users]
        
        # Update status to 'completed' with explicit UUID casting
        cur.execute("""
            UPDATE public.profiles
            SET onboarding_status = 'completed'
            WHERE id::text = ANY(%s);
        """, (uids,))
        
        updated_count = cur.rowcount
        conn.commit()
        
        print(f"Successfully updated {updated_count} users to 'completed'.")
        for uid, sid in users:
            print(f"Updated: {sid}")

        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Database Error: {e}")

if __name__ == "__main__":
    force_complete_onboarding()
