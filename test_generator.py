
from optimized_functions.schedule_generator import generate_schedules

def test():
    # Mock data for Spring 2026 courses
    # Format: course_sections_map = { 'CODE': [sections...] }
    
    mock_courses = {
        'CSE101': [
            {
                'id': 'cse101_01',
                'code': 'CSE101',
                'section': '1',
                'capacity': '30/35', # Valid
                'sessions': [
                    {'day': 'S M', 'startTime': '08:00 AM', 'endTime': '09:20 AM', 'type': 'Theory'}
                ]
            },
            {
                'id': 'cse101_02',
                'code': 'CSE101',
                'section': '2',
                'capacity': '35/35', # FULL - Should be ignored automatically
                'sessions': [
                    {'day': 'S M', 'startTime': '09:30 AM', 'endTime': '10:50 AM', 'type': 'Theory'}
                ]
            }
        ],
        'ENG101': [
            {
                'id': 'eng101_01',
                'code': 'ENG101',
                'section': '1',
                'capacity': '20/40', # Valid
                'sessions': [
                    {'day': 'S M', 'startTime': '08:00 AM', 'endTime': '09:20 AM', 'type': 'Theory'} # CONFLICT with CSE101 Sec 1
                ]
            },
            {
                'id': 'eng101_02',
                'code': 'ENG101',
                'section': '2',
                'capacity': '0/0', # INVALID - Should be ignored automatically
                'sessions': [
                    {'day': 'T R', 'startTime': '08:00 AM', 'endTime': '09:20 AM', 'type': 'Theory'}
                ]
            },
            {
                'id': 'eng101_03',
                'code': 'ENG101',
                'section': '3',
                'capacity': '10/40', # Valid
                'sessions': [
                    {'day': 'S M', 'startTime': '11:00 AM', 'endTime': '12:20 PM', 'type': 'Theory'} # VALID
                ]
            }
        ],
        'MAT101': [
            {
                'id': 'mat101_01',
                'code': 'MAT101',
                'section': '1',
                'capacity': '25/40',
                'sessions': [
                    {'day': 'T R', 'startTime': '11:00 AM', 'endTime': '12:20 PM', 'type': 'Theory'}
                ]
            }
        ]
    }

    print("--- Running Schedule Generator Test ---")
    print(f"Courses: {list(mock_courses.keys())}")
    
    # Run generator
    results = generate_schedules(mock_courses, filters={}, limit=10)
    
    print(f"\nFound {len(results)} valid combinations.")
    
    for i, schedule in enumerate(results):
        print(f"\nOption {i+1}:")
        for course in schedule:
            print(f"  - {course['code']} Section {course['section']} ({course['capacity']})")
            for s in course['sessions']:
                print(f"    {s['day']} {s['startTime']} - {s['endTime']}")

    # Expected: 
    # CSE101 must be Sec 1 (Sec 2 is full)
    # ENG101 cannot be Sec 1 (conflict with CSE101 S1)
    # ENG101 cannot be Sec 2 (0/0)
    # So ENG101 must be Sec 3
    # MAT101 must be Sec 1
    # Total combinations should be 1.

    if len(results) == 1:
        print("\nTEST SUCCESS: Generator correctly filtered full/invalid sections and found the only valid combination.")
    else:
        print(f"\nTEST FAILED: Expected 1 combination, but found {len(results)}.")

if __name__ == "__main__":
    test()
