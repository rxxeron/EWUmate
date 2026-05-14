import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def heal_user(user_id):
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        print(f"--- Healing User ID: {user_id} ---")
        
        # 1. Fetch actual enrollments for the active semester (Summer2026)
        semester = "summer2026"
        cur.execute("SELECT section_id FROM public.enrollments WHERE user_id = %s AND semester_code = %s", (user_id, semester))
        sections = [str(r[0]) for r in cur.fetchall()]
        print(f"Found {len(sections)} enrollments for {semester}: {sections}")
        
        # 2. Update profile.enrolled_sections (with proper casting)
        if sections:
            cur.execute("UPDATE public.profiles SET enrolled_sections = %s::uuid[] WHERE id = %s", (sections, user_id))
            print("Updated profiles.enrolled_sections")
        
        # 3. Ensure onboarding_status is 'completed'
        cur.execute("UPDATE public.profiles SET onboarding_status = 'completed' WHERE id = %s", (user_id,))
        print("Set onboarding_status to 'completed'")

        # 4. If they have a duplicate key issue in user_semester_states, let's check it
        cur.execute("SELECT semester_code FROM public.user_semester_states WHERE user_id = %s", (user_id,))
        states = cur.fetchall()
        print(f"User states in user_semester_states: {states}")

        conn.commit()
        cur.close()
        conn.close()
        print("Healing complete.")
    except Exception as e:
        print(f"Error during healing: {e}")

if __name__ == "__main__":
    heal_user("191aaf7c-9004-4164-9da0-518169b25d18")
