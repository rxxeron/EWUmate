import psycopg2

DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

sql_commands = """
-- Repair completed_courses credits using course_metadata
UPDATE completed_courses cc
SET credits = cm.credit_val
FROM course_metadata cm
WHERE UPPER(cc.course_code) = UPPER(cm.code)
  AND (cc.credits != cm.credit_val OR cc.credits = 3.0);
"""

def main():
    conn = None
    cur = None
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        print("Repairing completed_courses credits...")
        cur.execute(sql_commands)
        rowcount = cur.rowcount
        conn.commit()
        print(f"SUCCESS: {rowcount} courses repaired.")
    except Exception as e:
        print(f"ERROR: {e}")
        if conn: conn.rollback()
    finally:
        if cur: cur.close()
        if conn: conn.close()

if __name__ == '__main__':
    main()
