import psycopg2

try:
    conn = psycopg2.connect("postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres")
    cursor = conn.cursor()
    
    query_funcs = """
    SELECT proname, prosrc
    FROM pg_proc
    WHERE proname IN ('master_enrollment_sync', 'master_academic_sync', 'sync_profile_to_analytics', 'trigger_track_sync', 'set_completed_course_details', 'trg_calculate_live_projection');
    """
    
    cursor.execute(query_funcs)
    funcs = cursor.fetchall()
    
    with open("scratch/db_functions.txt", "w") as f:
        for p in funcs:
            f.write(f"--- Function: {p[0]} ---\n")
            f.write(f"{p[1]}\n\n")
            
except Exception as e:
    print(f"Error: {e}")
finally:
    if 'conn' in locals() and conn:
        cursor.close()
        conn.close()
