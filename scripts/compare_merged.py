import json

def load_json(filepath, encoding='utf-8'):
    try:
        with open(filepath, 'r', encoding=encoding) as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading {filepath}: {e}")
        return None

def compare_equivalence():
    merged_data = load_json('merged_courses.json', 'utf-8')
    metadata_data = load_json('course_metadata_full.json', 'utf-16')

    if not merged_data or not metadata_data:
        print("Data files missing or empty.")
        return

    # All valid codes from official metadata
    metadata_codes = {m['code'].strip().upper() for m in metadata_data}
    metadata_lookup = {m['code'].strip().upper(): m for m in metadata_data}

    equivalence_stats = {
        'valid_equivalence': [],
        'invalid_equivalence': [],
        'no_equivalence': [],
        'course_exists_in_metadata': [],
        'course_missing_from_metadata': []
    }

    for entry in merged_data:
        course_code = entry.get('course_code', '').strip().upper()
        equiv_code = entry.get('equivalence_code', '').strip().upper()

        if not course_code: continue

        # 1. Check if the course itself is in metadata
        if course_code in metadata_codes:
            equivalence_stats['course_exists_in_metadata'].append(course_code)
        else:
            equivalence_stats['course_missing_from_metadata'].append(course_code)

        # 2. Check the equivalence mapping
        if not equiv_code:
            equivalence_stats['no_equivalence'].append(course_code)
        elif equiv_code in metadata_codes:
            equivalence_stats['valid_equivalence'].append({
                'course': course_code,
                'equiv': equiv_code,
                'equiv_name': metadata_lookup[equiv_code].get('name')
            })
        else:
            equivalence_stats['invalid_equivalence'].append({
                'course': course_code,
                'equiv': equiv_code
            })

    print(f"--- Equivalence Check Results ---")
    print(f"Total courses in merged_courses.json: {len(merged_data)}")
    print(f"Courses already in Metadata: {len(equivalence_stats['course_exists_in_metadata'])}")
    print(f"Courses missing from Metadata: {len(equivalence_stats['course_missing_from_metadata'])}")
    print(f"\n--- Mapping Analysis ---")
    print(f"Valid Equivalent Matches (Exists in DB): {len(equivalence_stats['valid_equivalence'])}")
    print(f"Invalid Equivalent Codes (Not in DB): {len(equivalence_stats['invalid_equivalence'])}")
    print(f"No Equivalence defined: {len(equivalence_stats['no_equivalence'])}")

    if equivalence_stats['valid_equivalence']:
        print("\n--- Valid Mappings (Top 10) ---")
        for item in equivalence_stats['valid_equivalence'][:10]:
            print(f"{item['course']} -> {item['equiv']} ({item['equiv_name']})")

    if equivalence_stats['invalid_equivalence']:
        print("\n--- Invalid Mappings (Top 10) ---")
        for item in equivalence_stats['invalid_equivalence'][:10]:
            print(f"{item['course']} -> {item['equiv']} (!! Missing from Metadata !!)")

    if equivalence_stats['course_missing_from_metadata']:
        print("\n--- Courses to be ADDED to Metadata (Top 10) ---")
        for code in equivalence_stats['course_missing_from_metadata'][:10]:
            print(code)

if __name__ == "__main__":
    compare_equivalence()
