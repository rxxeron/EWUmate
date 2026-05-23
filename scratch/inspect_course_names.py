import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def find_duplicates():
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    # Let's get all courses where department is CSE or ICE.
    # Note: course codes start with 'CSE' or 'ICE'.
    cur.execute("""
        SELECT code, name, equivalent_code 
        FROM course_metadata 
        WHERE code LIKE 'CSE%' OR code LIKE 'ICE%'
        ORDER BY name, code;
    """)
    rows = cur.fetchall()
    
    # Group by normalized name
    import collections
    by_name = collections.defaultdict(list)
    for code, name, equiv in rows:
        normalized_name = " ".join(name.lower().split())
        by_name[normalized_name].append((code, name, equiv))
        
    print("--- Matches by Exact Name (case-insensitive & whitespace normalized) ---")
    match_count = 0
    for norm_name, list_courses in sorted(by_name.items()):
        if len(list_courses) > 1:
            # We only care if there is at least one CSE and one ICE course
            codes = [c[0] for c in list_courses]
            has_cse = any(c.startswith('CSE') for c in codes)
            has_ice = any(c.startswith('ICE') for c in codes)
            if has_cse and has_ice:
                match_count += 1
                print(f"\nGroup: {norm_name.title()}")
                for code, name, equiv in list_courses:
                    print(f"  Code: {code} | Name: {name} | Equivalent: {equiv}")
                    
    print(f"\nTotal duplicate groups found between CSE and ICE: {match_count}")
    
    cur.close()
    conn.close()

if __name__ == "__main__":
    find_duplicates()
