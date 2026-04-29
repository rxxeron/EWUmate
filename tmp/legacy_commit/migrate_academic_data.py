import psycopg2
import json
import decimal
from datetime import datetime

# Database Connection
DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

# Grade Point Configuration (Shared with Flutter GradeHelper)
grade_points = {
    'A+': 4.00, 'A': 3.75, 'A-': 3.50, 'B+': 3.25, 'B': 3.00, 'B-': 2.75,
    'C+': 2.50, 'C': 2.25, 'D': 2.00, 'F': 0.00,
    'S': 0, 'U': 0, 'W': 0, 'P': 0, 'I': 0, 'R': 0
}

def migrate_data(dry_run=True):
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        # 1. Fetch current semester summaries (The data source)
        print("Fetching semester summaries...")
        cur.execute("SELECT id, user_id, semester_code, courses FROM semester_summaries;")
        summaries = cur.fetchall()
        
        # 2. Backup current data (Precaution)
        backup_data = []
        for s in summaries:
            backup_data.append({
                'id': s[0], 'user_id': s[1], 
                'semester_code': s[2], 'courses': s[3]
            })
        
        with open('academic_backup.json', 'w') as f:
            json.dump(backup_data, f, indent=4)
        print(f"Safety Backup created: academic_backup.json ({len(summaries)} semesters)")

        # 3. Processing individual courses
        user_histories = {} # user_id -> list of sem_objects
        
        print("\nCrunching numbers...")
        for s_id, u_id, sem_code, courses in summaries:
            if u_id not in user_histories: user_histories[u_id] = []
            
            term_points = 0.0
            term_credits = 0.0
            
            # Map of courses for this semester to store relational-style
            cleaned_courses = []
            
            for c in courses:
                grade = c.get('grade', 'Ongoing')
                credits = float(c.get('credits', 0.0))
                point = grade_points.get(grade, 0.0)
                
                # PRECAUTION: Skip ongoing or non-GPA grades for the 'completed_courses' table
                if grade == 'Ongoing' or grade in ['S', 'U', 'W', 'P', 'I', 'R']:
                    continue

                if grade in grade_points:
                    term_points += (point * credits)
                    term_credits += credits
                
                cleaned_courses.append({
                    'code': c.get('code', 'UNK'),
                    'grade': grade,
                    'credits': credits,
                    'point': point
                })
            
            tgpa = term_points / term_credits if term_credits > 0 else 0.0
            
            user_histories[u_id].append({
                'semester_code': sem_code,
                'tgpa': round(tgpa, 2),
                'credits': term_credits,
                'courses': cleaned_courses
            })
            
            # Relational Insertion Into New Table
            if not dry_run:
                for c in cleaned_courses:
                    cur.execute("""
                        INSERT INTO completed_courses (user_id, semester_code, course_code, grade, credits, grade_point)
                        VALUES (%s, %s, %s, %s, %s, %s);
                    """, (u_id, sem_code, c['code'], c['grade'], c['credits'], c['point']))

        # 4. Final Cumulative Calculations and Profile Updates
        print("\nUpdating Profiles with cached 'past_history' JSON...")
        for u_id, semesters in user_histories.items():
            # Sort chronologically by year/term (Handles both 'spring_2024' and 'spring2024')
            def get_order(s):
                code = s['semester_code'].lower()
                # Find the numeric part (year)
                year_str = ''.join(filter(str.isdigit, code))
                year = int(year_str) if year_str else 0
                # Find the term part
                term = 0
                if 'spring' in code: term = 0
                elif 'summer' in code: term = 1
                elif 'fall' in code: term = 2
                return year * 10 + term
            
            semesters.sort(key=get_order)
            
            # Cumulative CGPA accumulation
            running_points = 0.0
            running_credits = 0.0
            for sem in semesters:
                running_points += sum(c['point'] * c['credits'] for c in sem['courses'] if c['grade'] in grade_points and c['grade'] not in ['S', 'U', 'W', 'P', 'I', 'R', 'Ongoing'])
                running_credits += sum(c['credits'] for c in sem['courses'] if c['grade'] in grade_points and c['grade'] not in ['S', 'U', 'W', 'P', 'I', 'R', 'Ongoing'])
                sem['cgpa'] = round(running_points / running_credits, 2) if running_credits > 0 else 0.0
            
            # Final Profile Writes
            final_json = json.dumps(semesters)
            final_credits = running_credits
            final_cgpa = 0.0
            if semesters:
                final_cgpa = semesters[-1].get('cgpa', 0.0)
            
            if not dry_run:
                cur.execute("""
                    UPDATE profiles 
                    SET past_history = %s, total_credits_earned = %s, cgpa = %s
                    WHERE id = %s;
                """, (final_json, final_credits, final_cgpa, u_id))
            else:
                print(f"DRY RUN: User {u_id} would be updated with {len(semesters)} semesters. Final CGPA: {final_cgpa}")

        if not dry_run:
            conn.commit()
            print("\nSUCCESS: Migration Complete!")
        else:
            print("\nDRY RUN COMPLETE: Checked schema but no database changes were made.")
            
    except Exception as e:
        print(f"ERROR: {e}")
        if conn: conn.rollback()
    finally:
        if cur: cur.close()
        if conn: conn.close()

if __name__ == '__main__':
    # Step 1: Migration Execution (LIVE)
    migrate_data(dry_run=False)
