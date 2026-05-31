import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"
target_email = "2025-2-50-009@std.ewubd.edu"

def delete_user():
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    try:
        # Step 1: Resolve user ID from auth.users
        cur.execute("""
            SELECT id, email FROM auth.users WHERE email = %s;
        """, (target_email,))
        user = cur.fetchone()
        
        if not user:
            print(f"No matching user found in auth.users for email: {target_email}")
            cur.close()
            conn.close()
            return
            
        user_id = user[0]
        email = user[1]
        print(f"Starting deletion process for user: {email} (ID: {user_id})")
        
        # We will delete from all child tables first in a transaction
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
            cur.execute(f"DELETE FROM {table} WHERE user_id = %s;", (user_id,))
            print(f"Deleted records from {table}: {cur.rowcount} rows affected.")
            
        # 2. Delete from tables referencing uploader_id
        for table in child_tables_uploader_id:
            cur.execute(f"DELETE FROM {table} WHERE uploader_id = %s;", (user_id,))
            print(f"Deleted records from {table}: {cur.rowcount} rows affected.")
            
        # 3. Delete from public.profiles
        cur.execute("DELETE FROM public.profiles WHERE id = %s;", (user_id,))
        print(f"Deleted records from public.profiles: {cur.rowcount} rows affected.")
        
        # 4. Delete from auth.users
        cur.execute("DELETE FROM auth.users WHERE id = %s;", (user_id,))
        print(f"Deleted records from auth.users: {cur.rowcount} rows affected.")
        
        # Commit the transaction
        conn.commit()
        print(f"\nDeletion successful! User {email} and all related data have been completely deleted.")
        
    except Exception as e:
        conn.rollback()
        print(f"An error occurred. Transaction rolled back. Error: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    delete_user()
