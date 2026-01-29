import re

def parse_exam_pdf(pdf_path, semester_id):
    import pdfplumber
    exams = []
    
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            tables = page.extract_tables()
            for table in tables:
                for row in table:
                    clean_row = [str(x).strip() if x else "" for x in row]
                    
                    if "Class" in clean_row[0] or "Date" in clean_row[1]: continue
                    if not any(clean_row): continue

                    class_pattern = clean_row[0] if len(clean_row) > 0 else ""
                    last_class_date = clean_row[1] if len(clean_row) > 1 else ""
                    exam_day = clean_row[2] if len(clean_row) > 2 else ""
                    exam_date = clean_row[3] if len(clean_row) > 3 else ""

                    if class_pattern and exam_date:
                        # Create unique ID for exam schedule?
                        # Maybe by class pattern
                        doc_id = f"EXAM_{semester_id}_{class_pattern}"
                        exams.append({
                            "docId": doc_id,
                            "class_days": class_pattern,
                            "last_class_date": last_class_date,
                            "exam_day": exam_day,
                            "exam_date": exam_date,
                            "semester": semester_id,
                            "type": "EXAM_SCHEDULE"
                        })
    return exams
