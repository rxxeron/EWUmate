import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

raw_emails = """
2019-3-80-005@std.ewubd.edu, 2021-2-77-009@std.ewubd.edu, 2022-2-10-086@std.ewubd.edu, 2022-2-60-035@std.ewubd.edu, 2023-1-10-117@std.ewubd.edu, 2023-1-10-211@std.ewubd.edu, 2023-2-10-307@std.ewubd.edu, 2023-2-40-062@std.ewubd.edu, 2023-3-10-266@std.ewubd.edu, 2023-3-10-282@std.ewubd.edu, 2023-3-11-185@std.ewubd.edu, 2023-3-22-031@std.ewubd.edu, 2023-3-60-048@std.ewubd.edu, 2023-3-60-077@std.ewubd.edu, 2023-3-60-171@std.ewubd.edu, 2023-3-60-189@std.ewubd.edu, 2023-3-60-263@std.ewubd.edu, 2023-3-60-364@std.ewubd.edu, 2023-3-60-382@std.ewubd.edu, 2023-3-77-080@std.ewubd.edu, 2024-1-10-123@std.ewubd.edu, 2024-1-10-337@std.ewubd.edu, 2024-1-70-004@std.ewubd.edu, 2024-1-80-003@std.ewubd.edu, 2024-1-80-005@std.ewubd.edu, 2024-3-10-387@std.ewubd.edu, 2024-3-10-577@std.ewubd.edu, 2024-3-10-657@std.ewubd.edu, 2024-3-22-011@std.ewubd.edu, 2024-3-22-041@std.ewubd.edu, 2024-3-60-041@std.ewubd.edu, 2024-3-60-144@std.ewubd.edu, 2024-3-60-365@std.ewubd.edu, 2024-3-77-094@std.ewubd.edu, 2024-3-77-108@std.ewubd.edu, 2024-3-80-067@std.ewubd.edu, 2025-1-10-146@std.ewubd.edu, 2025-1-10-236@std.ewubd.edu, 2025-1-10-398@std.ewubd.edu, 2025-1-10-437@std.ewubd.edu, 2025-1-27-021@std.ewubd.edu, 2025-1-33-076@std.ewubd.edu, 2025-1-40-046@std.ewubd.edu, 2025-1-42-037@std.ewubd.edu, 2025-1-50-041@std.ewubd.edu, 2025-1-60-154@std.ewubd.edu, 2025-1-60-263@std.ewubd.edu, 2025-1-60-280@std.ewubd.edu, 2025-1-77-075@std.ewubd.edu, 2025-1-77-148@std.ewubd.edu, 2025-2-10-051@std.ewubd.edu, 2025-2-10-109@std.ewubd.edu, 2025-2-10-125@std.ewubd.edu, 2025-2-10-131@std.ewubd.edu, 2025-2-10-247@std.ewubd.edu, 2025-2-10-279@std.ewubd.edu, 2025-2-10-418@std.ewubd.edu, 2025-2-10-490@std.ewubd.edu, 2025-2-11-007@std.ewubd.edu, 2025-2-22-016@std.ewubd.edu, 2025-2-22-078@std.ewubd.edu, 2025-2-27-005@std.ewubd.edu, 2025-2-30-014@std.ewubd.edu, 2025-2-50-013@std.ewubd.edu, 2025-2-50-021@std.ewubd.edu, 2025-2-60-049@std.ewubd.edu, 2025-2-60-052@std.ewubd.edu, 2025-2-60-079@std.ewubd.edu, 2025-2-60-085@std.ewubd.edu, 2025-2-60-125@std.ewubd.edu, 2025-2-60-215@std.ewubd.edu, 2025-2-60-284@std.ewubd.edu, 2025-2-60-328@std.ewubd.edu, 2025-2-60-345@std.ewubd.eud, 2025-2-60-414@std.ewubd.edu, 2025-2-60-419@std.ewubd.edu, 2025-2-60-433@std.ewubd.edu, 2025-2-60-502@std.ewubd.edu, 2025-2-77-107@std.ewubd.edu, 2025-2-77-111@std.ewubd.edu, 2025-2-77-128@std.ewubd.edu, 2025-3-10-027@std.ewubd.edu, 2025-3-10-030@std.ewubd.edu, 2025-3-10-106@std.ewubd.edu, 2025-3-10-126@std.ewubd.edu, 2025-3-10-363@std.ewubd.edu, 2025-3-22-034@std.ewubd.edu, 2025-3-22-049@std.ewubd.edu, 2025-3-22-071@std.ewubd.edu, 2025-3-22-086@std.ewubd.edu, 2025-3-27-026@std.ewubd.edu, 2025-3-27-040@std.ewubd.edu, 2025-3-27@std.ewubd.edu, 2025-3-30-018@std.ewubd.edu, 2025-3-33-002@std.ewubd.edu, 2025-3-40-063@std.ewubd.edu, 2025-3-50-011@std.ewubd.edu, 2025-3-60-029@std.ewubd.edu, 2025-3-60-113@std.ewubd.edu, 2025-3-60-115@std.ewubd.edu, 2025-3-60-257@std.ewubd.edu, 2025-3-60-274@std.ewubd.edu, 2025-3-60-306@std.ewubd.edu, 2025-3-60-312@std.ewubd.edu, 2025-3-60-337@std.ewubd.edu, 2025-3-60-477@std.ewubd.edu, 2025-3-70-011@std.ewubd.edu, 2025-3-70-087@std.ewubd.edu, 2025-3-70-101@std.ewubd.edu, 2025-3-77-002@std.ewubd.edu, 2025-3-77-015@std.ewubd.edu, 2025-3-77-133@std.ewubd.edu, 2026-1-10-106@std.ewubd.edu, 2026-1-10-136@std.ewubd.edu, 2026-1-11-020@std.ewubd.edu, 2026-1-22-023@std.ewubd.edu, 2026-1-27-015@std.ewubd.edu, 2026-1-60-012@std.ewubd.edu, 2026-1-60-035@std.ewubd.edu, 2026-1-70-003@std.ewubd.edu, 2026-1-70-015@std.ewubd.edu, 2026-1-77-009@std.ewubd.edu, 2026-1-77-010@std.ewubd.edu, 2026-1-80-053@std.ewubd.edu, 2026-1-93-010@std.ewubd.edu, 2026-2-10-008@std.ewubd.edu, 2026-2-10-019@std.ewubd.edu, 2026-2-10-021@std.ewubd.edu, 2026-2-10-054@std.ewubd.edu, 2026-2-10-096@std.ewubd.edu, 2026-2-10-126@std.ewubd.edu, 2026-2-10-135@std.ewubd.edu, 2026-2-10-142@std.ewubd.edu, 2026-2-10-174@std.ewubd.edu, 2026-2-10-185@std.ewubd.edu, 2026-2-10-218@std.ewubd.edu, 2026-2-10-247@std.ewubd.edu, 2026-2-10-249@std.ewubd.edu, 2026-2-10-277@std.ewubd.edu, 2026-2-11-058@std.ewubd.edu, 2026-2-11-087@std.ewubd.edu, 2026-2-22-018@std.ewubd.edu, 2026-2-22-051@std.ewubd.edu, 2026-2-22-117@std.ewubd.edu, 2026-2-27-003@std.ewubd.edu, 2026-2-27-024@std.ewubd.edu, 2026-2-27-032@std.ewubd.edu, 2026-2-27-062@std.ewubd.edu, 2026-2-27-063@std.ewubd.edu, 2026-2-27-083@std.ewubd.edu, 2026-2-30-003@std.ewubd.edu, 2026-2-30-031@std.ewubd.edu, 2026-2-33-010@std.ewubd.edu, 2026-2-40-032@std.ewubd.edu, 2026-2-40-061@std.ewubd.edu, 2026-2-50-024@std.ewubd.edu, 2026-2-60-019@std.ewubd.edu, 2026-2-60-104@std.ewubd.edu, 2026-2-60-133@std.ewubd.edu, 2026-2-60-239@std.ewubd.edu, 2026-2-60-259@std.ewubd.edu, 2026-2-60-297@std.ewubd.edu, 2026-2-60-300@std.ewubd.edu, 2026-2-60-306@std.ewubd.edu, 2026-2-60-410@std.ewubd.edu, 2026-2-60-501@std.ewubd.edu, 2026-2-60-517-@std.ewubd.edu, 2026-2-77-012@std.ewubd.edu, 2026-2-77-102@std.ewubd.edu, 2026-2-77-111@std.ewubd.edu, 2026-2-77-112@std.ewubd.edu, 2026-2-77-114@std.ewubd.edu, 2026-2-77-139@std.ewubd.edu, 2026-2-77-162@std.ewubd.edu, 2026-2-80-004@std.ewubd.edu, 2026-2-80-086@std.ewubd.edu, 2026-2-80-117@std.ewubd.edu, 2026-2-80-170@std.ewubd.edu, 2026-2-80-174@std.ewubd.edu, 2026-2-95-004@std.ewubd.edu, 2026-260-517@std.ewubd.edu, 2026-3-66-002@std.ewubd.edu, 2026-3-66-040@std.ewubd.edu, 2026-3-70-032@std.ewubd.edu, 2026210121@std.ewubd.edu, 2056-2-60-517@std.ewubd.edu, adnananik@gmail.com, afrinsumu587@gmail.com, alexgilbert506@gmail.com, ariafu371@gmail.com, asaduzzamanjubayer@gmail.com, azmainmohib2311@gmail.com, bijoysikder685@gmail.com, bityajitparbon@gmail.com, islamsanjida8220@gmail.com, mubinulmahin2006@gmail.com, nahidpokemon2@gmail.com, obaka347@gmail.com, prapti@std.ewubd.edu, rahmantowhidur158@gmail.com, saifulislamalamin321@std.ewubd.edu, samictg35@gmail.com, shrabonibd2020@gmail.com, sowmik1337@gmail.com, stsadik1971@gmail.com
"""

# Extract clean emails
emails = [e.strip() for e in raw_emails.replace('\n', ',').split(',') if e.strip()]
# Remove duplicates
emails = sorted(list(set(emails)))

def delete_all_listed_users():
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    try:
        # Step 1: Resolve user IDs from auth.users
        print(f"Total input unique emails to process: {len(emails)}")
        
        # We might have a lot of emails, so let's query in batches or in one go
        placeholders = ", ".join(["%s"] * len(emails))
        cur.execute(f"""
            SELECT id, email FROM auth.users WHERE email IN ({placeholders});
        """, emails)
        users = cur.fetchall()
        
        if not users:
            print("No matching users found in auth.users.")
            cur.close()
            conn.close()
            return
            
        user_ids = [u[0] for u in users]
        found_emails = [u[1] for u in users]
        print(f"Resolved {len(user_ids)} users from database matching target list.")
        
        # We will delete from all child tables in a transaction
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
        print("\nAll target users and their related data have been completely deleted from the database.")
        
    except Exception as e:
        conn.rollback()
        print(f"An error occurred. Transaction rolled back. Error: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    delete_all_listed_users()
