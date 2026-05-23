import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

target_emails = [
    "2026210121@std.ewubd.edu",
    "2056-2-60-517@std.ewubd.edu",
    "tester1@std.ewubd.edu",
    "saifulislamalamin321@std.ewubd.edu",
    "adnananik@gmail.com",
    "2026-260-517@std.ewubd.edu",
    "prapti@std.ewubd.edu",
    "2025-2-60-345@std.ewubd.eud",
    "2025-3-27@std.ewubd.edu",
    "2026-2-60-517-@std.ewubd.edu"
]

def delete_users():
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    try:
        # Step 1: Resolve user IDs from auth.users
        placeholders = ", ".join(["%s"] * len(target_emails))
        cur.execute(f"""
            SELECT id, email FROM auth.users WHERE email IN ({placeholders});
        """, target_emails)
        users = cur.fetchall()
        
        if not users:
            print("No matching users found in auth.users.")
            cur.close()
            conn.close()
            return
            
        user_ids = [u[0] for u in users]
        emails = [u[1] for u in users]
        print(f"Starting deletion process for {len(user_ids)} users: {emails}")
        
        # We will delete from all child tables first in a transaction
        # Let's list all child tables that have records or foreign keys referencing profiles/auth.users
        child_tables_user_id = [
            "public.semester_summaries",
            "public.enrollments",
            "public.completed_courses",
            "public.tasks",
            "public.semester_course_marks",
            "public.user_semester_states",
            "public.feedbacks",
            "public.notifications",
            "public.schedule_exceptions",
            "public.fcm_tokens"
        ]
        
        child_tables_uploader_id = [
            "public.study_materials"
        ]
        
        # 1. Delete from tables referencing user_id
        for table in child_tables_user_id:
            placeholders_ids = ", ".join(["%s"] * len(user_ids))
            cur.execute(f"DELETE FROM {table} WHERE user_id IN ({placeholders_ids});", user_ids)
            print(f"Deleted records from {table}: {cur.rowcount} rows affected.")
            
        # 2. Delete from tables referencing uploader_id
        for table in child_tables_uploader_id:
            placeholders_ids = ", ".join(["%s"] * len(user_ids))
            cur.execute(f"DELETE FROM {table} WHERE uploader_id IN ({placeholders_ids});", user_ids)
            print(f"Deleted records from {table}: {cur.rowcount} rows affected.")
            
        # 3. Delete from public.profiles
        placeholders_ids = ", ".join(["%s"] * len(user_ids))
        cur.execute(f"DELETE FROM public.profiles WHERE id IN ({placeholders_ids});", user_ids)
        print(f"Deleted records from public.profiles: {cur.rowcount} rows affected.")
        
        # 4. Delete from auth.users
        cur.execute(f"DELETE FROM auth.users WHERE id IN ({placeholders_ids});", user_ids)
        print(f"Deleted records from auth.users: {cur.rowcount} rows affected.")
        
        # Commit the transaction
        conn.commit()
        print("\nDeletion successful! All users and related data have been completely deleted.")
        
    except Exception as e:
        conn.rollback()
        print(f"An error occurred. Transaction rolled back. Error: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    delete_users()
