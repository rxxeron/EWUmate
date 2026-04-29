import psycopg2

DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def evolve_grade_scale():
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        # 1. Add if doesn't exist (policy column)
        print("Adding policy column...")
        cur.execute("ALTER TABLE grade_scale ADD COLUMN IF NOT EXISTS policy text DEFAULT 'modern';")
        
        # 2. Update existing to 'modern' explicitly if preferred, though default handles it
        cur.execute("UPDATE grade_scale SET policy='modern' WHERE policy IS NULL;")

        # 3. Add composite unique constraint if needed, or just insert carefully
        # cur.execute("ALTER TABLE grade_scale ADD CONSTRAINT unique_grade_policy UNIQUE (grade, policy);")
        
        # 4. Insert Legacy Scale
        print("Inserting legacy grades...")
        legacy_grades = [
            ('A+', 4.00, 80, '80% and above - Legacy', 'legacy'),
            ('A', 4.00, 75, '75% to less than 80% - Legacy', 'legacy'),
            ('A-', 3.70, 70, '70% to less than 75% - Legacy', 'legacy'),
            ('B+', 3.30, 65, '65% to less than 70% - Legacy', 'legacy'),
            ('B', 3.00, 60, '60% to less than 65% - Legacy', 'legacy'),
            ('B-', 2.70, 55, '55% to less than 60% - Legacy', 'legacy'),
            ('C+', 2.30, 50, '50% to less than 55% - Legacy', 'legacy'),
            ('C', 2.00, 45, '45% to less than 50% - Legacy', 'legacy'),
            ('C-', 1.70, 40, '40% to less than 45% - Legacy', 'legacy'),
            ('D+', 1.30, 35, '35% to less than 40% - Legacy', 'legacy'),
            ('D', 1.00, 30, '30% to less than 35% - Legacy', 'legacy'),
            ('F', 0.00, 0, 'Less than 30% - Legacy', 'legacy'),
            # Also add secondary grades for legacy policy
            ('S', 0.00, None, 'Satisfactory - Legacy', 'legacy'),
            ('U', 0.00, None, 'Unsatisfactory - Legacy', 'legacy'),
            ('I', 0.00, None, 'Incomplete - Legacy', 'legacy'),
            ('W', 0.00, None, 'Withdrawal - Legacy', 'legacy'),
            ('R', 0.00, None, 'Repeat - Legacy', 'legacy'),
            ('P', 0.00, None, 'Pass - Legacy', 'legacy'),
        ]
        
        for g in legacy_grades:
            cur.execute("""
                INSERT INTO grade_scale (grade, point, min_score, description, policy) 
                VALUES (%s, %s, %s, %s, %s)
                ON CONFLICT DO NOTHING;
            """, g)
            
        conn.commit()
        print("SUCCESS: Grade scale evolved with legacy support.")
        
    except Exception as e:
        print(f"Error: {e}")
        if conn: conn.rollback()
    finally:
        if cur: cur.close()
        if conn: conn.close()

if __name__ == '__main__':
    evolve_grade_scale()
