import re

def analyze():
    filepath = r"d:\EWUmate\EWUmate_Clean\ewumate_v2\user_emails.csv"
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    emails = [line.strip() for line in lines[1:] if line.strip()]
    
    print(f"Total emails loaded: {len(emails)}")
    
    # 1. Check basic email validation pattern
    email_regex = re.compile(r'^[\w\.-]+@[\w\.-]+\.\w+$')
    
    # 2. EWU Student email pattern: YYYY-S-DD-NNN@std.ewubd.edu
    # Years: e.g. 2021-2026. Semesters: 1, 2, 3. Departments: 2 digits. Student number: 3 digits (mostly).
    ewu_regex = re.compile(r'^\d{4}-\d-\d{2}-\d{3}@std\.ewubd\.edu$')
    
    anomalies = []
    
    for idx, email in enumerate(emails, start=2): # 1-based line index in CSV
        # Basic validation
        if not email_regex.match(email):
            anomalies.append((idx, email, "Invalid email structure (fails basic regex)"))
            continue
        
        # Check domain typos
        domain = email.split('@')[1]
        if 'ewubd' in domain and domain != 'std.ewubd.edu':
            anomalies.append((idx, email, f"Possible typo in domain: '{domain}' instead of 'std.ewubd.edu'"))
            continue
            
        # Check if it looks like a student ID email but doesn't match standard hyphen format
        username = email.split('@')[0]
        if domain == 'std.ewubd.edu':
            # Check for non-standard characters in username
            if '-' in username:
                parts = username.split('-')
                # If it's a student ID but doesn't have 4 parts, or parts are not numeric
                if len(parts) != 4 or not all(p.isdigit() for p in parts if p):
                    anomalies.append((idx, email, f"Non-standard student ID format (hyphenated but parts are wrong: {parts})"))
            else:
                # If it's purely numeric but missing hyphens
                if username.isdigit():
                    anomalies.append((idx, email, "Student ID email missing all hyphens"))
                else:
                    # Named email (like prapti@std.ewubd.edu), which is probably fine
                    pass

    print("\n--- ANOMALIES FOUND ---")
    for idx, email, desc in anomalies:
        print(f"Line {idx:3d}: {email:<40} -> {desc}")

if __name__ == "__main__":
    analyze()
