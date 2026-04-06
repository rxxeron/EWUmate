import json
import re

def merge_data():
    # 1. Load Bulletin Data (Parsed from PDF)
    try:
        with open('parsed_courses_final.json', 'r') as f:
            bulletin_list = json.load(f)
    except FileNotFoundError:
        bulletin_list = []
        
    # Standardize Bulletin: Ensure codes are uppercase and no hyphens
    bulletin_data = {}
    for item in bulletin_list:
        code = item['code'].upper().replace('-', '').replace(' ', '')
        bulletin_data[code] = {
            'code': code,
            'name': item['name'],
            'credit': item['credit'],
            'source': 'bulletin'
        }

    # 2. Load Existing DB Data (merged_courses.json)
    try:
        with open('merged_courses.json', 'r') as f:
            db_list = json.load(f)
    except FileNotFoundError:
        db_list = []

    # 3. Merge: Prioritize Bulletin data, fill gaps with DB data
    final_data = bulletin_data.copy()
    new_from_db = 0
    
    for item in db_list:
        # DB fields are 'Code', 'Name', 'Credit'
        orig_code = item.get('Code', '')
        if not orig_code:
            continue
            
        code = orig_code.upper().replace('-', '').replace(' ', '')
        
        if code not in final_data:
            final_data[code] = {
                'code': code,
                'name': item.get('Name'),
                'credit': item.get('Credit'),
                'source': 'merged_courses'
            }
            new_from_db += 1
        else:
            # If it's already there, we keep the Bulletin version but maybe 
            # log that we have a duplicate if names are wildly different
            pass

    # 4. Save Final Master List
    master_list = sorted(list(final_data.values()), key=lambda x: x['code'])
    with open('final_master_courses.json', 'w') as f:
        json.dump(master_list, f, indent=2)

    print(f"Merge Complete!")
    print(f"Total Bulletin courses: {len(bulletin_data)}")
    print(f"Added from merged_courses.json: {new_from_db}")
    print(f"Final Master Course List: {len(master_list)}")

if __name__ == "__main__":
    merge_data()
