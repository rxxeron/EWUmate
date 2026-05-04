import psycopg2
import uuid

conn = psycopg2.connect('postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres')
cur = conn.cursor()

# Get all null section enrollments for spring2026
cur.execute("SELECT id, user_id, course_code, semester_code FROM enrollments WHERE section_id IS NULL AND semester_code = 'Spring2026'")
rows = cur.fetchall()

if rows:
    # First get all course sections to map course_code -> an arbitrary section_id
    cur.execute("SELECT course_code, (array_agg(id))[1] FROM courses_spring2026 GROUP BY course_code")
    course_sections = {r[0]: r[1] for r in cur.fetchall()}
    
    updated = 0
    null_users = set()
    for row_id, uid, ccode, scode in rows:
        sec_id = course_sections.get(ccode)
        if sec_id:
            # use row id to update so we don't mess with compound keys easily
            cur.execute("UPDATE enrollments SET section_id = %s WHERE id = %s", (sec_id, row_id))
            updated += 1
            null_users.add(uid)
            
    conn.commit()
    print(f'Fixed {updated} enrollments with valid section_ids.')
    
    if null_users:
        user_list = tuple(null_users)
        if len(user_list) == 1:
            cur.execute("DELETE FROM user_semester_states WHERE user_id = %s AND semester_code = 'Spring2026'", (user_list[0],))
        else:
            cur.execute("DELETE FROM user_semester_states WHERE user_id IN %s AND semester_code = 'Spring2026'", (user_list,))
        conn.commit()
        print(f'Purged cached grid for {len(null_users)} users so it will sync on next load.')
else:
    print('No null section_ids found.')
