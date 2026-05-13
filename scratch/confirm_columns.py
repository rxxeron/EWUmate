import psycopg2

def confirm_cols():
    try:
        conn = psycopg2.connect("postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres")
        cursor = conn.cursor()
        
        for table in ['courses_spring2026', 'courses_summer2026']:
            print(f"\nColumns in {table}:")
            cursor.execute(f"SELECT column_name FROM information_schema.columns WHERE table_name = '{table}' ORDER BY ordinal_position")
            cols = [r[0] for r in cursor.fetchall()]
            for c in cols:
                print(f"  - {c}")
                
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if 'conn' in locals() and conn:
            cursor.close()
            conn.close()

if __name__ == "__main__":
    confirm_cols()
