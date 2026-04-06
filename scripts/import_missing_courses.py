import json
import psycopg2

def load_json(filepath, encoding='utf-8'):
    try:
        with open(filepath, 'r', encoding=encoding) as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading {filepath}: {e}")
        return None

def import_courses():
    merged_data = load_json('merged_courses.json', 'utf-8')
    metadata_data = load_json('course_metadata_full.json', 'utf-16')

    if not merged_data or not metadata_data:
        print("Data files missing.")
        return

    # Existing metadata codes
    metadata_codes = {m['code'].strip().upper() for m in metadata_data}

    # Find the missing courses
    missing_courses = []
    seen_in_import = set()

    for entry in merged_data:
        code = entry.get('course_code', '').strip().upper()
        if not code or code in metadata_codes or code in seen_in_import:
            continue
            
        seen_in_import.add(code)
        missing_courses.append({
            'code': code,
            'name': entry.get('name'),
            'credit': float(entry.get('credit', 3.0)),
            'equiv': entry.get('equivalence_code', '').strip().upper() or None
        })

    if not missing_courses:
        print("No missing courses found.")
        return

    print(f"Found {len(missing_courses)} new courses to import.")

    # Database Connection
    try:
        conn = psycopg2.connect("postgresql://postgres:postgres@127.0.0.1:54322/postgres")
        cur = conn.cursor()

        # Insert query
        insert_query = """
        INSERT INTO course_metadata (code, name, credit_val, equivalent_code)
        VALUES (%s, %s, %s, %s)
        ON CONFLICT (code) DO NOTHING;
        """

        for course in missing_courses:
            cur.execute(insert_query, (
                course['code'],
                course['name'],
                course['credit'],
                course['equiv']
            ))

        conn.commit()
        print(f"Successfully imported {len(missing_courses)} courses to Supabase.")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Database error: {e}")

if __name__ == "__main__":
    import_courses()
