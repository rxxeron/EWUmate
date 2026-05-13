import psycopg2

def find_duplicates():
    try:
        conn = psycopg2.connect("postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres")
        cursor = conn.cursor()
        
        # Find cases where user_id and course_code are same but semester_code differs only by case
        query = """
        SELECT user_id, course_code, lower(semester_code), count(*)
        FROM semester_course_marks
        GROUP BY user_id, course_code, lower(semester_code)
        HAVING count(*) > 1;
        """
        
        cursor.execute(query)
        records = cursor.fetchall()
        
        print(f"Found {len(records)} duplicate cases (same user, same course, different semester case)")
        for row in records[:10]:
            print(f"User: {row[0]} | Course: {row[1]} | Sem: {row[2]} | Count: {row[3]}")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if 'conn' in locals() and conn:
            cursor.close()
            conn.close()

if __name__ == "__main__":
    find_duplicates()
