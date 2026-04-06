import json
import re

def analyze_with_7_formula():
    # 1. Load Data
    try:
        with open('parsed_courses_final.json', 'r') as f:
            bulletin_list = json.load(f)
    except FileNotFoundError:
        print("Missing parsed_courses_final.json")
        return
        
    try:
        with open('merged_courses.json', 'r') as f:
            db_list = json.load(f)
    except FileNotFoundError:
        print("Missing merged_courses.json")
        return

    # Normalize functions
    def normalize(code):
        return code.upper().replace('-', '').replace(' ', '')

    def get_pattern_variants(code):
        m = re.match(r'([A-Z]+)(\d+)([A-Z]*)', code)
        if not m:
            return [code]
        prefix, num, suffix = m.groups()
        variants = [code]
        if len(num) == 3:
            variants.append(prefix + '7' + num + suffix)
        elif len(num) == 4 and num.startswith('7'):
            variants.append(prefix + num[1:] + suffix)
        return variants

    bulletin_map = {normalize(d['code']): d for d in bulletin_list}
    db_map = {normalize(d['course_code']): d for d in db_list}

    results = []
    bulletin_matched = set()
    db_matched = set()

    # Match Logic
    for b_code, b_data in bulletin_map.items():
        variants = get_pattern_variants(b_code)
        for variant in variants:
            if variant in db_map:
                d_data = db_map[variant]
                match_type = 'direct' if b_code == variant else '7_formula'
                
                results.append({
                    'bulletin_code': b_code,
                    'db_code': variant,
                    'match_type': match_type,
                    'bulletin_name': b_data['name'],
                    'db_name': d_data['name'],
                    'bulletin_credit': str(b_data['credit']).strip(),
                    'db_credit': str(d_data['credit']).strip(),
                    'consistent_credit': str(b_data['credit']).strip() == str(d_data['credit']).strip()
                })
                bulletin_matched.add(b_code)
                db_matched.add(variant)
                break

    # Stats
    summary = {
        'total_bulletin': len(bulletin_map),
        'total_db': len(db_map),
        'total_matched': len(results),
        'not_in_db': sorted(list(set(bulletin_map.keys()) - bulletin_matched)),
        'not_in_bulletin': sorted(list(set(db_map.keys()) - db_matched)),
        'matches': results
    }

    with open('bulletin_db_match_report.json', 'w') as f:
        json.dump(summary, f, indent=2)

    print("Reconciliation Analysis Complete!")
    print(f"Total Bulletin courses: {len(bulletin_map)}")
    print(f"Total entries in DB: {len(db_map)}")
    print(f"Courses matched using 7-formula: {len(results)}")
    
    mismatched_credits = [r for r in results if not r['consistent_credit']]
    print(f"Matches with conflicting credits: {len(mismatched_credits)}")
    
    if mismatched_credits:
        print("\nTop 5 Credit Conflicts:")
        for m in mismatched_credits[:5]:
            print(f"  {m['bulletin_code']} ({m['bulletin_credit']}) vs {m['db_code']} ({m['db_credit']}) | {m['bulletin_name']}")

if __name__ == "__main__":
    analyze_with_7_formula()
