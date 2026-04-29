import psycopg2
import json

DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

# Grade Point Configuration (Shared)
grade_points = {
    'A+': 4.00, 'A': 3.75, 'A-': 3.50, 'B+': 3.25, 'B': 3.00, 'B-': 2.75,
    'C+': 2.50, 'C': 2.25, 'D': 2.00, 'F': 0.00
}

def cleanup_ongoing():
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        # 1. DELETE from completed_courses
        print("Cleaning up Ongoing courses and spring2026 records from completed_courses table...")
        cur.execute("DELETE FROM completed_courses WHERE grade = 'Ongoing' OR semester_code IN ('spring_2026', 'spring2026');")
        rows_deleted = cur.rowcount
        print(f"DELETED: {rows_deleted} records removed.")

        # 2. RE-SYNC per-user caches (profiles.past_history)
        print("\nRe-syncing profile caches...")
        
        # Fetch all remaining completed courses
        cur.execute("SELECT user_id, semester_code, course_code, grade, credits, grade_point FROM completed_courses ORDER BY semester_code;")
        courses = cur.fetchall()
        
        # Group by user and semester
        user_histories = {}
        for u_id, sem_code, c_code, grade, cr, pt in courses:
            if u_id not in user_histories: user_histories[u_id] = {}
            if sem_code not in user_histories[u_id]: user_histories[u_id][sem_code] = {'courses': [], 'credits': 0.0, 'points': 0.0}
            
            user_histories[u_id][sem_code]['courses'].append({
                'code': c_code,
                'grade': grade,
                'credits': float(cr),
                'point': float(pt)
            })
            user_histories[u_id][sem_code]['credits'] += float(cr)
            user_histories[u_id][sem_code]['points'] += (float(pt) * float(cr))

        # Update each profile
        for u_id, history in user_histories.items():
            semesters_list = []
            
            total_points = 0.0
            total_credits = 0.0
            
            # Sort chronologically (Simpler sort manually since we're recomputing)
            sorted_sems = sorted(history.keys()) # Alpha sort is usually fine for semester keys if they are standardized
            
            # Better sort helper
            def get_order(sem_code):
                try:
                    code = sem_code.lower()
                    year_str = ''.join(filter(str.isdigit, code))
                    year = int(year_str) if year_str else 0
                    term = 0
                    if 'spring' in code: term = 0
                    elif 'summer' in code: term = 1
                    elif 'fall' in code: term = 2
                    return year * 10 + term
                except: return 0
                
            sorted_sems = sorted(history.keys(), key=get_order)

            for sem_code in sorted_sems:
                sem_data = history[sem_code]
                tgpa = sem_data['points'] / sem_data['credits'] if sem_data['credits'] > 0 else 0.0
                
                total_points += sem_data['points']
                total_credits += sem_data['credits']
                cgpa = total_points / total_credits if total_credits > 0 else 0.0
                
                semesters_list.append({
                    'semester_code': sem_code,
                    'tgpa': round(tgpa, 2),
                    'cgpa': round(cgpa, 2),
                    'credits': round(sem_data['credits'], 1),
                    'courses': sem_data['courses']
                })

            final_cgpa = semesters_list[-1]['cgpa'] if semesters_list else 0.0
            
            cur.execute("""
                UPDATE profiles 
                SET past_history = %s, total_credits_earned = %s, cgpa = %s
                WHERE id = %s;
            """, (json.dumps(semesters_list), total_credits, final_cgpa, u_id))
            print(f"UPDATED: Profile {u_id} refreshed with {len(semesters_list)} semesters.")

        conn.commit()
        print("\nCleanup Successful.")
        
    except Exception as e:
        print(f"ERROR: {e}")
        if conn: conn.rollback()
    finally:
        if cur: cur.close()
        if conn: conn.close()

if __name__ == '__main__':
    cleanup_ongoing()
