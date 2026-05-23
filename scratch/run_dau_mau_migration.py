import psycopg2
import sys

DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def run_migration():
    print("Connecting to Supabase PostgreSQL database...")
    try:
        conn = psycopg2.connect(DATABASE_URL)
        conn.autocommit = True
        cur = conn.cursor()
        print("Connected successfully!")
        
        # 1. Create daily_activity table
        print("Step 1: Creating 'daily_activity' table and indexes...")
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS public.daily_activity (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
            activity_date DATE NOT NULL,
            last_active_at TIMESTAMPTZ NOT NULL,
            created_at TIMESTAMPTZ DEFAULT now(),
            CONSTRAINT daily_activity_user_date_unique UNIQUE (user_id, activity_date)
        );
        
        CREATE INDEX IF NOT EXISTS idx_daily_activity_date ON public.daily_activity(activity_date);
        """
        cur.execute(create_table_sql)
        print("Table and index created.")

        # 2. Create trigger function and trigger
        print("Step 2: Creating trigger function and trigger on 'profiles' table...")
        trigger_sql = """
        CREATE OR REPLACE FUNCTION public.log_daily_user_activity()
        RETURNS TRIGGER AS $$
        BEGIN
          IF NEW.last_active_at IS NOT NULL THEN
            INSERT INTO public.daily_activity (user_id, activity_date, last_active_at)
            VALUES (
              NEW.id, 
              (NEW.last_active_at AT TIME ZONE 'Asia/Dhaka')::date,
              NEW.last_active_at
            )
            ON CONFLICT (user_id, activity_date) 
            DO UPDATE SET last_active_at = EXCLUDED.last_active_at;
          END IF;
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;

        DROP TRIGGER IF EXISTS on_profile_activity ON public.profiles;

        CREATE TRIGGER on_profile_activity
          AFTER INSERT OR UPDATE OF last_active_at ON public.profiles
          FOR EACH ROW
          EXECUTE FUNCTION public.log_daily_user_activity();
        """
        cur.execute(trigger_sql)
        print("Trigger function and trigger created.")

        # 3. Create high-performance metrics view
        print("Step 3: Creating rolling active user metrics view...")
        view_sql = """
        CREATE OR REPLACE VIEW public.daily_active_users_metrics AS
        WITH unique_dates AS (
          SELECT DISTINCT activity_date 
          FROM public.daily_activity
        )
        SELECT 
          ud.activity_date,
          (
            SELECT COUNT(DISTINCT sub.user_id)::int
            FROM public.daily_activity sub
            WHERE sub.activity_date = ud.activity_date
          ) AS dau,
          (
            SELECT COUNT(DISTINCT sub.user_id)::int
            FROM public.daily_activity sub
            WHERE sub.activity_date BETWEEN ud.activity_date - INTERVAL '29 days' AND ud.activity_date
          ) AS mau,
          (
            SELECT COUNT(DISTINCT sub.user_id)::int
            FROM public.daily_activity sub
            WHERE sub.activity_date BETWEEN ud.activity_date - INTERVAL '364 days' AND ud.activity_date
          ) AS yau
        FROM unique_dates ud;
        """
        cur.execute(view_sql)
        print("Rolling metrics view created successfully!")

        # 4. Enable RLS and create policy + grants
        print("Step 4: Setting up RLS, security policies and permissions...")
        security_sql = """
        ALTER TABLE public.daily_activity ENABLE ROW LEVEL SECURITY;

        DROP POLICY IF EXISTS "Admins can view daily_activity" ON public.daily_activity;

        CREATE POLICY "Admins can view daily_activity" ON public.daily_activity
            FOR SELECT USING (auth.uid() IN (SELECT user_id FROM public.admin_users));

        GRANT ALL ON TABLE public.daily_activity TO service_role, postgres;
        GRANT SELECT ON TABLE public.daily_activity TO authenticated, anon;

        GRANT ALL ON TABLE public.daily_active_users_metrics TO service_role, postgres;
        GRANT SELECT ON TABLE public.daily_active_users_metrics TO authenticated, anon;
        """
        cur.execute(security_sql)
        print("Security settings and grants configured.")

        # 5. Backfill historical data from profiles.created_at and profiles.last_active_at
        print("Step 5: Seeding and backfilling historical active user records...")
        backfill_sql = """
        -- Seed 1: Login on profile creation (signup)
        INSERT INTO public.daily_activity (user_id, activity_date, last_active_at)
        SELECT id, (created_at AT TIME ZONE 'Asia/Dhaka')::date, created_at
        FROM public.profiles
        WHERE created_at IS NOT NULL
        ON CONFLICT (user_id, activity_date) DO NOTHING;

        -- Seed 2: Last recorded session
        INSERT INTO public.daily_activity (user_id, activity_date, last_active_at)
        SELECT id, (last_active_at AT TIME ZONE 'Asia/Dhaka')::date, last_active_at
        FROM public.profiles
        WHERE last_active_at IS NOT NULL
        ON CONFLICT (user_id, activity_date) DO NOTHING;
        """
        cur.execute(backfill_sql)
        print("Historical backfill completed successfully!")

        # 6. Verify backfill counts
        cur.execute("SELECT COUNT(*) FROM public.daily_activity")
        count = cur.fetchone()[0]
        print(f"Migration finished! Seeded {count} daily user activity records.")
        
        cur.close()
        conn.close()
        print("Database connection closed cleanly.")
        return True
    except Exception as e:
        print(f"ERROR: Database migration failed! Reason: {e}", file=sys.stderr)
        return False

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
