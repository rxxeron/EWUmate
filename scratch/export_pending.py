import psycopg2
import csv

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def export_pending_to_csv():
    try:
        conn = psycopg2.connect(conn_url)
        cur = conn.cursor()
        
        query = """
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
        """
        cur.execute(query)
        rows = cur.fetchall()
        
        filename = "pending_registrations.csv"
        with open(filename, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['Email', 'Name', 'Student ID', 'Status', 'Joined At'])
            writer.writerows(rows)
            
        print(f"Successfully exported {len(rows)} users to {filename}")

        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Database Error: {e}")

if __name__ == "__main__":
    export_pending_to_csv()
