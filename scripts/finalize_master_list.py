import json
import re

def finalize_master():
    # Load Sources
    with open('parsed_courses_final.json', 'r') as f:
        bulletin_list = json.load(f)
    with open('merged_courses.json', 'r') as f:
        db_list = json.load(f)

    def normalize(code):
        return code.upper().replace('-', '').replace(' ', '')

    def get_base_code(code):
        m = re.match(r'([A-Z]+)(\d+)([A-Z]*)', code)
        if m:
            prefix, num, suffix = m.groups()
            if len(num) == 4 and num.startswith('7'):
                return prefix + num[1:] + suffix
        return code

    # Maps
    bulletin_map = {normalize(d['code']): d for d in bulletin_list}
    db_map = {normalize(d['course_code']): d for d in db_list}

    # Consolidated Master Map
    master_map = {}

    # 1. Process all Database records (Source of Truth for credits)
    for code, data in db_map.items():
        base = get_base_code(code)
        master_map[code] = {
            'code': code,
            'name': data.get('name', ''),
            'credit': str(data.get('credit', '3')).strip(),
            'source': 'database'
        }

    # 2. Process all Bulletin records
    for b_code, b_data in bulletin_map.items():
        # Check for direct match or 7-pattern match in master
        match_found = False
        
        # Try direct
        if b_code in master_map:
            # Update name if more descriptive, but KEEP DB credits
            if len(b_data['name']) > len(master_map[b_code]['name']):
                master_map[b_code]['name'] = b_data['name']
            match_found = True
        else:
            # Try 7-pattern variants
            m = re.match(r'([A-Z]+)(\d+)([A-Z]*)', b_code)
            if m:
                prefix, num, suffix = m.groups()
                if len(num) == 3:
                    bi_version = prefix + '7' + num + suffix
                    if bi_version in master_map:
                        # Linked to DB bi-semester version
                        if len(b_data['name']) > len(master_map[bi_version]['name']):
                            master_map[bi_version]['name'] = b_data['name']
                        match_found = True

        if not match_found:
            # New course from bulletin
            master_map[b_code] = {
                'code': b_code,
                'name': b_data['name'],
                'credit': str(b_data['credit']).strip(),
                'source': 'bulletin'
            }

    # Save
    final_list = sorted(list(master_map.values()), key=lambda x: x['code'])
    with open('final_master_courses.json', 'w') as f:
        json.dump(final_list, f, indent=2)

    print(f"Master Merge Complete!")
    print(f"Total Unique Courses: {len(final_list)}")
    print(f"Database contribution: {len(db_map)}")
    print(f"New Bulletin additions: {len(final_list) - len(db_map)}")

if __name__ == "__main__":
    finalize_master()
