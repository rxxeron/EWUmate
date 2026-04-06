import pdfplumber
import re
import json

pdf_path = r"C:\Users\Farzana Safa\Downloads\ewuundergraduate-bulletin-14th-edition-doc-version.pdf"
COURSE_CODE_PATTERN = re.compile(r'^([A-Z]{2,5})\s*[-–\s]*(\d{3}[A-Z]*)', re.IGNORECASE)

def clean_name(name):
    name = re.split(r'\.\s', name)[0]
    junk_patterns = [
        r'Theory\s*Laboratory\s*Total',
        r'Credit\s*and\s*Teaching\s*Scheme:?',
        r'Teaching\s*Scheme:?',
        r'Page\s*\d+\s*of\s*\d+',
    ]
    for pattern in junk_patterns:
        name = re.sub(pattern, '', name, flags=re.IGNORECASE)
    name = re.sub(COURSE_CODE_PATTERN, '', name).strip()
    return name.strip(': ,-')

def parse_bulletin(start_page, end_page):
    results = []
    current_course = None
    
    with pdfplumber.open(pdf_path) as pdf:
        for i in range(start_page - 1, min(len(pdf.pages), end_page)):
            text = pdf.pages[i].extract_text()
            if not text: continue
            
            lines = text.split('\n')
            for line in lines:
                line = line.strip()
                if not line or 'Page' in line and 'of' in line:
                    continue
                
                # Header Check
                match = COURSE_CODE_PATTERN.match(line)
                if match:
                    code_part = match.group(0)
                    remaining = line[len(code_part):].strip()
                    if remaining.startswith(':') or (len(remaining) > 0 and remaining[0].isupper()):
                        if current_course and current_course.get('credit'):
                            results.append(current_course)
                        
                        code = f"{match.group(1).upper()}{match.group(2)}"
                        current_course = {'code': code, 'name': clean_name(remaining), 'credit': None}
                        continue

                if not current_course: continue

                # Highly Precise Credit Check
                l_lower = line.lower()
                if 'credit' in l_lower:
                    # Isolate the segment containing "Credit" and the number
                    # Stop at any punctuation that usually separates credits from prerequisites
                    # e.g., "Credits: 3; Prerequisite..." or "Credits: 3.0, Prerequisite..."
                    credit_segment = re.split(r'[;,\-\s](?=pre)', l_lower)[0]
                    # Find first number *after* the word "credit"
                    match_num = re.search(r'credit[s\s:-]*(\d+\.?\d*)', credit_segment)
                    if match_num:
                        current_course['credit'] = match_num.group(1)
                    else:
                        # Fallback for table format: take last number if "total" is present
                        nums = re.findall(r'(\d+\.?\d*)', line)
                        if 'total' in l_lower and nums:
                            current_course['credit'] = nums[-1]
                        elif nums:
                            # Final fallback: take the first number that isn't the course numeric part
                            # num_part is the numeric sequence within the code (e.g., 430 from ACT430)
                            num_match = re.search(r'\d+', current_course['code'])
                            num_part = num_match.group() if num_match else ""
                            for n in nums:
                                if n != num_part:
                                    current_course['credit'] = n
                                    break
                
                # Name Continuation
                elif not current_course['credit']:
                    if len(line.split()) < 8 and not any(k in l_lower for k in ['this', 'concept', 'theory', 'lab']):
                        cleaned_line = clean_name(line)
                        if cleaned_line and cleaned_line not in current_course['name']:
                            current_course['name'] += " " + cleaned_line

            if current_course and current_course.get('credit'):
                results.append(current_course)
                current_course = None

    return results

if __name__ == "__main__":
    print("Running Final High-Precision extraction...")
    data = parse_bulletin(229, 524)
    final_data = []
    seen = set()
    for d in data:
        if d['code'] not in seen:
            # Final touch: clean up the names one last time
            d['name'] = clean_name(d['name'])
            final_data.append(d)
            seen.add(d['code'])
            
    with open('parsed_courses_final.json', 'w') as f:
        json.dump(final_data, f, indent=2)
    print(f"Extraction complete. Found {len(final_data)} unique courses.")
