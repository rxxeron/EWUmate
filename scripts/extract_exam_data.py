import pdfplumber
import json
import re

pdf_path = r"C:\Users\ibnea\Downloads\Mobile App\Mobile App\flutter_v2_new\694258f5656d7153021981.pdf"
output_path = r"C:\Users\ibnea\Downloads\Mobile App\Mobile App\flutter_v2_new\functions\data\exam_schedule_extracted.json"

exams = []
current_semester = "Spring 2026"  # Identifying from context or filename usually, defaulting here

with pdfplumber.open(pdf_path) as pdf:
    print(f"Processing {len(pdf.pages)} pages...")
    for page in pdf.pages:
        tables = page.extract_tables()
        for table in tables:
            for row in table:
                # Clean row
                clean_row = [str(x).strip() if x else "" for x in row]
                
                # Check for header
                if "Class" in clean_row[0] or "Date" in clean_row[1]:
                    continue
                
                # Expected structure: [Class Days, Last Class Date, Exam Day, Exam Date]
                # Filter out empty rows
                if not any(clean_row): continue

                # Safe access
                class_pattern = clean_row[0] if len(clean_row) > 0 else ""
                last_class_date = clean_row[1] if len(clean_row) > 1 else ""
                exam_day = clean_row[2] if len(clean_row) > 2 else ""
                exam_date = clean_row[3] if len(clean_row) > 3 else ""

                if class_pattern and exam_date:
                     exams.append({
                        "class_days": class_pattern,
                        "last_class_date": last_class_date,
                        "exam_day": exam_day,
                        "exam_date": exam_date,
                        "semester": current_semester,
                        "type": "EXAM_SCHEDULE"
                    })

print(f"Extracted {len(exams)} exam entries.")

with open(output_path, 'w') as f:
    json.dump(exams, f, indent=2)

print(f"Saved to {output_path}")
