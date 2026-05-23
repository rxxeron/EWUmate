import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def deploy_trigger():
    sql = """
    CREATE OR REPLACE FUNCTION public.trg_delete_semester_course_marks_on_drop()
    RETURNS TRIGGER AS $$
    BEGIN
      -- Delete from semester_course_marks
      DELETE FROM public.semester_course_marks
      WHERE user_id = OLD.user_id
        AND UPPER(REPLACE(semester_code, ' ', '')) = UPPER(REPLACE(OLD.semester_code, ' ', ''))
        AND UPPER(REPLACE(course_code, ' ', '')) = UPPER(REPLACE(OLD.course_code, ' ', ''));

      -- Delete from semester_course_stats
      DELETE FROM public.semester_course_stats
      WHERE user_id = OLD.user_id
        AND UPPER(REPLACE(semester, ' ', '')) = UPPER(REPLACE(OLD.semester_code, ' ', ''))
        AND UPPER(REPLACE(course_code, ' ', '')) = UPPER(REPLACE(OLD.course_code, ' ', ''));
        
      RETURN OLD;
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER;

    DROP TRIGGER IF EXISTS delete_semester_course_marks_trigger ON public.enrollments;
    CREATE TRIGGER delete_semester_course_marks_trigger
    AFTER DELETE ON public.enrollments
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_delete_semester_course_marks_on_drop();
    """
    
    try:
        print("Connecting to Supabase Database...")
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        print("Executing SQL to deploy drop trigger...")
        cur.execute(sql)
        conn.commit()
        cur.close()
        conn.close()
        print("Trigger successfully deployed!")
    except Exception as e:
        print(f"Error deploying trigger: {e}")

if __name__ == "__main__":
    deploy_trigger()
