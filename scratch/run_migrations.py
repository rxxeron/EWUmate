import os
import psycopg2

def run_migrations():
    # 1. Load env file
    env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env")
    db_url = None
    if os.path.exists(env_path):
        with open(env_path, "r") as f:
            for line in f:
                if line.startswith("DATABASE_URL="):
                    db_url = line.split("=", 1)[1].strip().strip('"').strip("'")
                    break
    
    if not db_url:
        print("Error: DATABASE_URL not found in .env")
        return
        
    print(f"Connecting to database...")
    
    sql_script = """
    -- 1. Create a global security definer helper to check admin status
    CREATE OR REPLACE FUNCTION public.is_admin()
    RETURNS BOOLEAN SECURITY DEFINER AS $$
    BEGIN
      RETURN EXISTS (
        SELECT 1 FROM public.admin_users WHERE user_id = auth.uid()
      );
    END;
    $$ LANGUAGE plpgsql;

    -- 2. Enable RLS on all administrative tables
    ALTER TABLE public.feedbacks ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.tutorials ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.study_materials ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.faculty_office_hours ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.drive_accounts ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

    -- 3. Drop existing policies to prevent conflicts
    DROP POLICY IF EXISTS "Admins have full access on feedbacks" ON public.feedbacks;
    DROP POLICY IF EXISTS "Admins have full access on tutorials" ON public.tutorials;
    DROP POLICY IF EXISTS "Admins have full access on study_materials" ON public.study_materials;
    DROP POLICY IF EXISTS "Admins have full access on faculty_office_hours" ON public.faculty_office_hours;
    DROP POLICY IF EXISTS "Admins have full access on drive_accounts" ON public.drive_accounts;
    DROP POLICY IF EXISTS "Admins have full access on notifications" ON public.notifications;

    -- 4. Create simple, clean Admin Authorization Policies utilizing the global helper
    CREATE POLICY "Admins have full access on feedbacks" ON public.feedbacks
        FOR ALL TO authenticated USING (public.is_admin());

    CREATE POLICY "Admins have full access on tutorials" ON public.tutorials
        FOR ALL TO authenticated USING (public.is_admin());

    CREATE POLICY "Admins have full access on study_materials" ON public.study_materials
        FOR ALL TO authenticated USING (public.is_admin());

    CREATE POLICY "Admins have full access on faculty_office_hours" ON public.faculty_office_hours
        FOR ALL TO authenticated USING (public.is_admin());

    CREATE POLICY "Admins have full access on drive_accounts" ON public.drive_accounts
        FOR ALL TO authenticated USING (public.is_admin());

    CREATE POLICY "Admins have full access on notifications" ON public.notifications
        FOR ALL TO authenticated USING (public.is_admin());

    -- 5. Enable public/user policies (e.g. read access for students, if applicable)
    DROP POLICY IF EXISTS "Students can view tutorials" ON public.tutorials;
    CREATE POLICY "Students can view tutorials" ON public.tutorials
        FOR SELECT USING (is_active = true);

    DROP POLICY IF EXISTS "Students can view approved study materials" ON public.study_materials;
    CREATE POLICY "Students can view approved study materials" ON public.study_materials
        FOR SELECT USING (status = 'approved');

    DROP POLICY IF EXISTS "Students can view office hours" ON public.faculty_office_hours;
    CREATE POLICY "Students can view office hours" ON public.faculty_office_hours
        FOR SELECT USING (true);
    """
    
    try:
        conn = psycopg2.connect(db_url)
        conn.autocommit = True
        cursor = conn.cursor()
        
        print("Executing SQL migrations...")
        cursor.execute(sql_script)
        print("SQL Migrations executed successfully!")
        
        cursor.close()
        conn.close()
        print("Connection closed.")
    except Exception as e:
        print(f"Error executing migrations: {e}")

if __name__ == "__main__":
    run_migrations()
