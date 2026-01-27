import re
import pdfplumber

def parse_exam_pdf(pdf_path, semester_id):
    exams = []
    
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            # Using table extraction is usually best for exam schedules as they are grid-like
            tables = page.extract_tables()
            
            for table in tables:
                if not table: continue
                
                # Heuristic: Identify header row to skip? 
                # Usually row 0 is header.
                
                for row in table:
                    # Normalize row: replace None with ""
                    clean_row = [str(x).strip() if x else "" for x in row]
                    
                    # Skip empty rows
                    if not any(clean_row): continue
                    
                    # Skip Header Rows
                    # Logic: if row contains "Class Days" or "Exam Date", it's a header
                    row_text_joined = " ".join(clean_row).lower()
                    if "class" in row_text_joined and "date" in row_text_joined:
                        continue
                        
                    # Expecting at least 4 columns usually: 
                    # Col 0: Class Pattern (ST 08:30-10:00)
                    # Col 1: Last Class Date
                    # Col 2: Exam Day
                    # Col 3: Exam Date
                    
                    if len(clean_row) < 4: continue
                    
                    class_pattern = clean_row[0]
                    last_class_date = clean_row[1]
                    exam_day = clean_row[2]
                    exam_date = clean_row[3]
                    
                    # Valid row must have a class pattern and an exam date
                    if not class_pattern or not exam_date: continue
                    
                    # Generate ID
                    # Sanitize pattern for ID
                    safe_pattern = re.sub(r'[^A-Z0-9:-]', '', class_pattern.upper())
                    doc_id = f"EXAM_{semester_id}_{safe_pattern}"
                    
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
