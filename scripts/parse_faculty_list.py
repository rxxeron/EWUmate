import pdfplumber
import re
import json

pdf_path = r"C:\Users\Farzana Safa\Downloads\Faculty List Summer 2026 (2).pdf"
# Pattern to match course codes like CSE101, ACT430, etc.
# Matches 2-5 uppercase letters followed by all digits and optional trailing letters
COURSE_CODE_PATTERN = re.compile(r'^([A-Z]{2,5})(\d+[A-Z]*)')

def extract_unique_codes():
    unique_codes = set()
    
    print(f"Opening PDF: {pdf_path}")
    with pdfplumber.open(pdf_path) as pdf:
        for i, page in enumerate(pdf.pages):
            text = page.extract_text()
            if not text:
                continue
            
            lines = text.split('\n')
            for line in lines:
                line = line.strip()
                # Try to find a course code at the start of the line
                match = COURSE_CODE_PATTERN.match(line)
                if match:
                    # Normalizing to uppercase and ensuring no hyphens (already seems hyphen-free)
                    code = match.group(0).upper()
                    unique_codes.add(code)
            
            if (i + 1) % 10 == 0:
                print(f"Processed {i + 1} pages...")

    return sorted(list(unique_codes))

if __name__ == "__main__":
    codes = extract_unique_codes()
    output_file = 'unique_faculty_courses.json'
    
    with open(output_file, 'w') as f:
        json.dump(codes, f, indent=2)
    
    print(f"\nExtraction complete!")
    print(f"Found {len(codes)} unique course codes.")
    print(f"Results saved to: {output_file}")
    
    # Print a few examples
    if codes:
        print("\nFirst 10 codes found:")
        print(codes[:10])
