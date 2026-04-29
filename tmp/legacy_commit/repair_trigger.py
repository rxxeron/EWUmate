import psycopg2

DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

fixed_function_sql = """
CREATE OR REPLACE FUNCTION public.sync_profile_enrolled_sections()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    user_track text;
    active_sem text;
    enrolled_ids text[];
BEGIN
    -- 1. Get user's track
    SELECT track INTO user_track FROM profiles WHERE id = COALESCE(NEW.user_id, OLD.user_id);
    IF user_track IS NULL THEN
        user_track := 'tri_semester'; -- Fallback
    END IF;

    -- 2. Get current active semester for that track
    SELECT initcap(replace(replace(lower(current_semester_code), ' ', ''), '_', ''))
    INTO active_sem
    FROM active_semester
    WHERE track = user_track::"public"."academic_track"; -- FIXED Type from track_type

    IF active_sem IS NULL THEN
        RETURN COALESCE(NEW, OLD);
    END IF;

    -- 3. Aggregate course references for the active semester
    -- Fix: Joining on course_code instead of code
    EXECUTE format(
        'SELECT array_agg(DISTINCT %%L || %%L || e.course_code || %%L || COALESCE(c.section_number, %%L)) ' ||
        'FROM enrollments e ' ||
        'LEFT JOIN %%I c ON e.course_code = c.course_code ' || -- FIXED column name: course_code
        'WHERE e.user_id = %%L AND initcap(replace(replace(lower(e.semester_code), %%L, %%L), %%L, %%L)) = %%L',
        active_sem, '_', '_', 'N/A',
        'courses_' || lower(active_sem),
        COALESCE(NEW.user_id, OLD.user_id), ' ', '', '_', '', active_sem
    ) INTO enrolled_ids;

    -- 4. Update profiles
    UPDATE profiles
    SET enrolled_sections = COALESCE(enrolled_ids, '{}')
    WHERE id = COALESCE(NEW.user_id, OLD.user_id);

    RETURN COALESCE(NEW, OLD);
END;
$function$;
"""

def main():
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        print("Executing Trigger Repair (v3 - Fixing schema-mismatch)...")
        # Ensure we use raw SQL to avoid the %% interpolation issue if not careful
        cur.execute(fixed_function_sql.replace("%%", "%"))
        conn.commit()
        print("SUCCESS: Database trigger fixed.")
    except Exception as e:
        print(f"ERROR: {e}")
        if conn: conn.rollback()
    finally:
        if cur: cur.close()
        if conn: conn.close()

if __name__ == '__main__':
    main()
