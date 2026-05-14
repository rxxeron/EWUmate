import psycopg2

db_url = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def count_usage():
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        
        tables = [
            ('profiles', 'admitted_semester'),
            ('enrollments', 'semester_code'),
            ('completed_courses', 'semester_code'),
            ('active_semester', 'current_semester_code'),
            ('active_semester', 'next_semester_code')
        ]
        
        codes = ['Summer2026', 'summer_2026', 'summer2026']
        
        for code in codes:
            print(f"\nUsage for '{code}':")
            for table, col in tables:
                cur.execute(f"SELECT COUNT(*) FROM {table} WHERE {col} = %s;", (code,))
                count = cur.fetchone()[0]
                if count > 0:
                    print(f"  {table}.{col}: {count}")
                    
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    count_usage()
