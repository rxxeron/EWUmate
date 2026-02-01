
import firebase_admin
from firebase_admin import credentials, firestore
import sys
import os

# Add functions folder to path so we can import schedule_generator
sys.path.append(os.path.join(os.getcwd(), 'functions'))

try:
    from schedule_generator import generate_schedules
except ImportError as e:
    print(f"Error importing schedule_generator: {e}")
    sys.exit(1)

# Initialize Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate("config/serviceAccountKey.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

SEMESTER_COLLECTION = "courses_summer2026" # Attempt lower case as per user request prompt 
# If fail, try other casings.

def test_live_generation():
    print(f"--- Connecting to Firestore Collection: {SEMESTER_COLLECTION} ---")
    
    # 1. Verify connection and schema by fetching one doc
    docs = list(db.collection(SEMESTER_COLLECTION).limit(5).stream())
    
    if not docs:
        print(f"Warning: No documents found in '{SEMESTER_COLLECTION}'. Trying 'courses_Summer2026'...")
        SEMESTER_COLLECTION_ALT = "courses_Summer2026"
        docs = list(db.collection(SEMESTER_COLLECTION_ALT).limit(5).stream())
        if not docs:
            print(f"Error: Could not find any documents in {SEMESTER_COLLECTION} or {SEMESTER_COLLECTION_ALT}.")
            return
        else:
            print(f"Found documents in '{SEMESTER_COLLECTION_ALT}'. Using that.")
            collection_name = SEMESTER_COLLECTION_ALT
    else:
        collection_name = SEMESTER_COLLECTION

    print("Sample Document Structure:")
    sample = docs[0].to_dict()
    print(f"Keys provided: {list(sample.keys())}")
    print(f"ID: {docs[0].id}, Code: {sample.get('code')}, Name: '{sample.get('courseName')}'")
    
    # Check for ANY capacity with '/'
    has_slash = False
    for d in docs:
        if '/' in str(d.to_dict().get('capacity', '')):
            has_slash = True
            break
    if not has_slash:
        print("WARNING: Sample documents do not contain '/' in capacity. Likely all '0'.")
    
    # 2. Pick some courses to test
    # Let's try to find a few distinct codes from the first 20 docs
    # test_courses = set()
    # all_sections_stream = db.collection(collection_name).limit(50).stream()
    # for d in all_sections_stream:
    #     data = d.to_dict()
    #     if 'code' in data:
    #         test_courses.add(data['code'])
    #     if len(test_courses) >= 3:
    #         break
            
    # target_courses = list(test_courses)
    target_courses = ['ICE204', 'MAT102', 'ICE107', 'CHE109']
    
    if not target_courses:
        print("Could not find any course codes to test.")
        return

    print(f"\n--- Testing Generation for Courses: {target_courses} ---")
    
    # Target specific combination
    target_sections = {
        'ICE107': '12',
        'ICE204': '14',
        'CHE109': '6',
        'MAT102': '4'
    }

    # 3. Fetch all sections for these courses (simulate what main.py does)
    course_sections_map = {}
    from schedule_generator import is_section_valid, sections_conflict
    
    specific_sections = []

    for code in target_courses:
        query = db.collection(collection_name).where("code", "==", code)
        sections = [d.to_dict() for d in query.stream()]
        print(f"Fetched {len(sections)} sections for {code}")
        
        # DEBUG: Check validity of SPECIFIC TARGETS
        valid_count = 0
        target_sec_id = target_sections.get(code)
        
        for s in sections:
            sec_num = str(s.get('section'))
            is_valid = is_section_valid(s, filters={})
            
            if sec_num == target_sec_id:
                 print(f"  [TARGET FOUND] {code} Sec {sec_num}")
                 # Print detailed times for visual check
                 for sess in s.get('sessions', []):
                     print(f"      -> {sess.get('day')} {sess.get('startTime')} - {sess.get('endTime')}")
                 specific_sections.append(s)

            if is_valid:
                valid_count += 1
        
        course_sections_map[code] = sections

    print("\n--- Checking Conflicts for Target Combination ---")
    if len(specific_sections) != 4:
        print(f"Error: Could not find all 4 specific sections. Found {len(specific_sections)}.")
    else:
        conflict_found = False
        import itertools
        for s1, s2 in itertools.combinations(specific_sections, 2):
            if sections_conflict(s1, s2):
                print(f"❌ CONFLICT DETECTED between:")
                print(f"   {s1['code']} Sec {s1['section']} AND {s2['code']} Sec {s2['section']}")
                # Print sessions again to show why
                print(f"   {s1['code']}: {[ (x['day'], x['startTime']) for x in s1['sessions']]}")
                print(f"   {s2['code']}: {[ (x['day'], x['startTime']) for x in s2['sessions']]}")
                conflict_found = True
        
        if not conflict_found:
            print("✅ ZERO CONFLICTS found in this combination!")
            print("If it did not appear in the generator list, it might be due to ordering/limit or 'full' check being flaky.")

    # 4. Run Generator
    print("\nRunning generate_schedules...")
    filters = {
        # 'exclude_days': ['Friday'] # items optional
    }
    
    import time
    start_time = time.time()
    # User requested limit 50
    results = generate_schedules(course_sections_map, filters=filters, limit=50)
    end_time = time.time()
    
    print(f"\n--- Results ---")
    print(f"Time taken: {end_time - start_time:.4f} seconds")
    print(f"Schedules Found: {len(results)}")
    
    for i, schedule in enumerate(results):
        print(f"\nSchedule {i+1}:")
        for section in schedule:
            # Handle multiple faculties across sessions
            faculties = set()
            # 1. Check root
            if section.get('faculty'):
                faculties.add(section.get('faculty'))
            # 2. Check sessions
            if section.get('sessions'):
                for s in section['sessions']:
                    if s.get('faculty'):
                        faculties.add(s.get('faculty'))
            
            faculty_str = " / ".join(sorted(list(faculties))) if faculties else "TBA"

            print(f"  [{section.get('code')}] Sec {section.get('section')} | {section.get('capacity')} | {faculty_str}")
            # Print times
            if 'sessions' in section:
                for s in section['sessions']:
                    # Show faculty per session if specific
                    s_fac = s.get('faculty', '')
                    s_fac_viz = f"[{s_fac}]" if s_fac else ""
                    print(f"     -> {s.get('day', '')} {s.get('startTime', '')}-{s.get('endTime', '')} {s_fac_viz}")
            else:
                 print(f"     -> No sessions info")

if __name__ == "__main__":
    test_live_generation()
