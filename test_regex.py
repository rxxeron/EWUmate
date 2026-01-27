import re

# Logic extracted from optimized parser_course.py
def test_parsing(line):
    print(f"Testing line: '{line}'")
    
    time_pattern = re.compile(r"(\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)\s*-\s*\d{1,2}:\d{2}\s*(?:AM|PM|am|pm))", re.IGNORECASE)
    capacity_token_pattern = re.compile(r"^(\d+)/(\d+)$")
    
    time_match = time_pattern.search(line)
    if not time_match:
        print("No time found.")
        return

    full_time = time_match.group(1)
    start_idx = time_match.start()
    
    pre_time_text = line[:start_idx].strip()
    
    tokens = pre_time_text.split()
    
    # Simulate the logic
    # A. Remove days from end
    day_tokens = []
    while tokens:
        curr = tokens[-1].replace(',', '').upper()
        if len(curr) <= 3 and all(c in 'SMTWRFA' for c in curr):
             day_tokens.insert(0, curr)
             tokens.pop()
        else:
             break
    
    if not tokens: return
    
    code = tokens[0]
    if len(tokens) > 1:
        section = tokens[1]
        middle_tokens = tokens[2:]
    else:
        middle_tokens = []
        
    # C. Capacity Check
    capacity = "0/0"
    faculty = ""
    
    capacity_idx = -1
    for i, tok in enumerate(middle_tokens):
        if capacity_token_pattern.match(tok):
            capacity_idx = i
            capacity = tok
            break
            
    if capacity_idx != -1:
        faculty = " ".join(middle_tokens[:capacity_idx])
    else:
        faculty = " ".join(middle_tokens)
        
    print(f"  Code: {code}")
    print(f"  Section: {section}")
    print(f"  Faculty: '{faculty}'")
    print(f"  Capacity: {capacity}")
    print("-" * 20)

# Test Cases
test_parsing("CSE101 1 Dr. Smith 30/40 S M 08:30 AM - 10:00 AM Room 101")
test_parsing("ENG101 2 Prof. Doe 0/0 T R 11:30 AM - 01:00 PM Room 202")
test_parsing("MAT202 5 S. Khan 35/35 W 02:00 PM - 03:30 PM")
