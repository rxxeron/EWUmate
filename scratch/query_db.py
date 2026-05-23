import pg8000.dbapi

def main():
    conn = pg8000.dbapi.connect(
        host="aws-1-ap-south-1.pooler.supabase.com",
        database="postgres",
        user="postgres.jwygjihrbwxhehijldiz",
        password="EWUmaterh12",
        port=5432
    )
    cursor = conn.cursor()
    
    # Let's write a query to fetch both student_id from profiles and email from auth.users
    cursor.execute("""
        SELECT p.student_id, u.email, p.full_name, p.onboarding_status
        FROM profiles p
        JOIN auth.users u ON p.id = u.id
        WHERE p.student_id LIKE '2025-3-27%%'
           OR p.student_id LIKE '2025%%22%%055%%'
           OR p.student_id LIKE '%%517'
           OR p.student_id LIKE '%%121'
           OR p.student_id LIKE '%%165'
           OR p.student_id LIKE '%%157'
    """)
    rows = cursor.fetchall()
    
    print("--- MATCHED USERS FROM DB (profiles + auth.users) ---")
    for row in rows:
        print(f"student_id: {row[0]:<15} | email: {row[1]:<35} | name: {row[2]:<25} | status: {row[3]}")
        
    cursor.close()
    conn.close()

if __name__ == "__main__":
    main()
