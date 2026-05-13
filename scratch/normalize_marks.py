import psycopg2
import json

def normalize_marks():
    try:
        conn = psycopg2.connect("postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres")
        cursor = conn.cursor()
        
        # 1. Fetch all marks
        cursor.execute("SELECT id, user_id, semester_code, course_code, obt_mid, obt_quizzes FROM semester_course_marks")
        marks = cursor.fetchall()
        
        to_delete = set()
        to_update = []
        
        seen = {} # (user_id, lower_semester_code, course_code) -> record
        
        for m in marks:
            m_id, u_id, sem, code, mid, quizzes = m
            low_sem = sem.lower().replace(' ', '')
            key = (u_id, low_sem, code)
            
            if key in seen:
                # Duplicate found!
                other = seen[key]
                other_id, other_u, other_sem, other_code, other_mid, other_quizzes = other
                
                # Logic: Keep the one with more data
                current_score = (1 if mid is not None else 0) + (len(quizzes) if quizzes else 0)
                other_score = (1 if other_mid is not None else 0) + (len(other_quizzes) if other_quizzes else 0)
                
                if current_score > other_score:
                    to_delete.add(other_id)
                    seen[key] = m
                    if sem != low_sem:
                        to_update.append((low_sem, m_id))
                    # Remove from update if it was there
                    to_update = [x for x in to_update if x[1] != other_id]
                else:
                    to_delete.add(m_id)
            else:
                seen[key] = m
                if sem != low_sem:
                    to_update.append((low_sem, m_id))

        print(f"Plan: Update {len(to_update)} records, Delete {len(to_delete)} duplicates")
        
        # 1. Execute deletes first to free up unique constraints
        for m_id in to_delete:
            cursor.execute("DELETE FROM semester_course_marks WHERE id = %s", (m_id,))
            
        # 2. Execute updates
        for low_sem, m_id in to_update:
            cursor.execute("UPDATE semester_course_marks SET semester_code = %s WHERE id = %s", (low_sem, m_id))
            
        conn.commit()
        print("Database normalized successfully.")
            
    except Exception as e:
        print(f"Error: {e}")
        if conn: conn.rollback()
    finally:
        if 'conn' in locals() and conn:
            cursor.close()
            conn.close()

if __name__ == "__main__":
    normalize_marks()
