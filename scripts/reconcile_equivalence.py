import json
import re

def reconcile():
    # Load all unique faculty codes
    with open('unique_faculty_courses.json', 'r') as f:
        faculty_codes = json.load(f)
    
    # Load all bulletin data
    with open('final_master_courses.json', 'r') as f:
        bulletin_data = {d['code']: d for d in json.load(f)}
    
    bulletin_codes = set(bulletin_data.keys())
    
    final_mapping = []
    still_missing = []
    
    for f_code in faculty_codes:
        match_found = False
        
        # 1. Direct Match
        if f_code in bulletin_codes:
            final_mapping.append({
                'faculty_code': f_code,
                'matched_code': f_code,
                'match_type': 'direct',
                'data': bulletin_data[f_code]
            })
            match_found = True
        
        # 2. Pattern Matching (Both Directions)
        if not match_found:
            m = re.match(r'([A-Z]+)(\d+)([A-Z]*)', f_code)
            if m:
                prefix, num, suffix = m.groups()
                
                # Case A: Faculty has 4 digits starting with 7, try removing it
                if len(num) == 4 and num.startswith('7'):
                    base_code = prefix + num[1:] + suffix
                    if base_code in bulletin_codes:
                        final_mapping.append({
                            'faculty_code': f_code,
                            'matched_code': base_code,
                            'match_type': '7_removed',
                            'data': bulletin_data[base_code]
                        })
                        match_found = True
                        
                # Case B: Faculty has 3 digits, try adding a 7
                elif not match_found and len(num) == 3:
                    bi_code = prefix + '7' + num + suffix
                    if bi_code in bulletin_codes:
                        final_mapping.append({
                            'faculty_code': f_code,
                            'matched_code': bi_code,
                            'match_type': '7_added',
                            'data': bulletin_data[bi_code]
                        })
                        match_found = True

        if not match_found:
            still_missing.append(f_code)

    # Save consolidated results
    output = {
        'total_faculty_courses': len(faculty_codes),
        'total_matched': len(final_mapping),
        'total_missing': len(still_missing),
        'matched_courses': final_mapping,
        'missing_courses': still_missing
    }
    
    with open('faculty_consolidated_data.json', 'w') as f:
        json.dump(output, f, indent=2)
        
    print(f"Aggressive Reconciliation Complete!")
    print(f"Matched: {len(final_mapping)} / {len(faculty_codes)}")
    print(f"Still Missing: {len(still_missing)}")

    
    if final_mapping:
        print("\nExample Matches:")
        for m in final_mapping[:5]:
            print(f"  {m['faculty_code']} <--> {m['matched_code']} ({m['data']['name']})")

if __name__ == "__main__":
    reconcile()
