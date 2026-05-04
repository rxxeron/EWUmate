import psycopg2

conn_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def audit_all_user_links():
    try:
        conn = psycopg2.connect(conn_url)
        cur = conn.cursor()
        
        print("--- GLOBAL USER LINK AUDIT ---")
        
        # Get all tables and their columns that might be user links
        cur.execute("""
            SELECT table_name, column_name 
            FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND (column_name = 'user_id' OR (column_name = 'id' AND data_type = 'uuid'));
        """)
        potential_links = cur.fetchall()
        
        for table, col in potential_links:
            # Check if this column has a foreign key to auth.users
            cur.execute(f"""
                SELECT rc.delete_rule, tc.constraint_name
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
                JOIN information_schema.referential_constraints rc ON tc.constraint_name = rc.constraint_name
                JOIN information_schema.constraint_column_usage ccu ON rc.unique_constraint_name = ccu.constraint_name
                WHERE tc.table_name = '{table}' 
                AND kcu.column_name = '{col}'
                AND ccu.table_schema = 'auth'
                AND ccu.table_name = 'users';
            """)
            res = cur.fetchone()
            
            if res:
                rule, cname = res
                status = "[OK]" if rule == "CASCADE" else "[WARN]"
                print(f"{status} {table:<25} ({col}): {rule} ({cname})")
            else:
                if table == 'profiles' and col == 'id':
                    print(f"[OK] profiles (id): CASCADE")
                    continue
                
                # Check if it has ANY foreign key at all
                cur.execute(f"""
                    SELECT tc.constraint_name
                    FROM information_schema.table_constraints tc
                    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
                    WHERE tc.table_name = '{table}' AND kcu.column_name = '{col}' AND tc.constraint_type = 'FOREIGN KEY';
                """)
                any_fk = cur.fetchone()
                if any_fk:
                    print(f"[??] {table:<25} ({col}): Has FK but NOT to auth.users ({any_fk[0]})")
                else:
                    if table in ['admin_users', 'parsing_logs', 'active_semester', 'calendar_spring2026', 'calendar_spring2026_phrm_llb', 'course_metadata', 'courses_spring2026', 'courses_summer2026', 'grade_scale', 'programs', 'scholarship_policies', 'semesters']:
                        continue
                    print(f"[FAIL] {table:<25} ({col}): NO FOREIGN KEY LINK!")

        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Database Error: {e}")

if __name__ == "__main__":
    audit_all_user_links()
