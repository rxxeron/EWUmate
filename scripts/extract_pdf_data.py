import re
import json
import os

# Try to import pypdf, handle missing dependency
try:
    from pypdf import PdfReader
except ImportError:
    print("Error: 'pypdf' library is missing. Please run: pip install pypdf")
    exit(1)

def extract_courses_from_pdf(pdf_path, output_path):
    print(f"Processing {pdf_path}...")
    
    if not os.path.exists(pdf_path):
        print(f"Error: File not found at {pdf_path}")
        return

    reader = PdfReader(pdf_path)
    text = ""
    
    # Extract text from all pages
    for page in reader.pages:
        text += page.extract_text() + "\n"

    courses = []
    
    # Improved Pattern:
    # 1. Code: 3-4 uppercase letters, optional space, 3 digits
    # 2. Separator: Optional colon or dot
    # 3. Title: Everything until the credits number
    # 4. Credits: A number (integer or float like 1.5 or 3+1) at the end of the line
    
    pattern = re.compile(r'([A-Z]{3,4}\s?\d{3})[:.]?\s+(.+?)\s+(\d+(?:\.\d+)?(?:\+\d+(?:\.\d+)?)?)')
    
    lines = text.split('\n')
    
    for line in lines:
        line = line.strip()
        
        # Skip lines that are likely prerequisites or credits definitions
        if re.match(r'^(Prerequisite|Credits|Credit|Pre-requisite)', line, re.IGNORECASE):
            continue
            
        match = pattern.search(line)
        if match:
            code = match.group(1).replace(" ", "") 
            title = match.group(2).strip()
            credits_str = match.group(3).strip()
            
            # Additional Filtering
            # 1. Title shouldn't be too long or too short
            if len(title) < 3 or len(title) > 100:
                continue
            
            # 2. Title shouldn't contain keywords indicating it's a prerequisite line that got matched
            if "Prerequisite" in title or "Credit" in title:
                continue

            # 3. Code shouldn't be common words (sometimes 'AND 101' might match)
            if code.startswith("AND"):
                continue

            course = {
                "code": code,
                "name": title,
                "credits": credits_str
            }
            courses.append(course)

    # Remove duplicates based on code
    unique_courses = {}
    for c in courses:
        # Simple heuristic: keep the longest title if duplicates found (often truncated vs full)
        if c['code'] in unique_courses:   
            if len(c['name']) > len(unique_courses[c['code']]['name']):
                unique_courses[c['code']] = c
        else:
            unique_courses[c['code']] = c
    
    # Convert to Dict keyed by Code for easier lookup
    final_dict = {}
    for c in list(unique_courses.values()):
        # Parse credits here too for cleaner metadata
        try:
            parts = str(c['credits']).split('+')
            sum_credits = sum(float(p.strip()) for p in parts if p.strip())
            c['credits'] = sum_credits
        except:
            pass # Keep original string if parse fails
            
        final_dict[c['code']] = c
        
    # Write to JSON
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(final_dict, f, indent=2)
        
    print(f"Successfully extracted {len(final_dict)} courses to {output_path}")

if __name__ == "__main__":
    pdf_file = "ewuundergraduate-bulletin-14th-edition-doc-version.pdf"
    json_file = "functions/data/courses.json"
    extract_courses_from_pdf(pdf_file, json_file)
