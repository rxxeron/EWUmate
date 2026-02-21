import re
import pdfplumber
import logging
import io

def parse_exam_pdf(pdf_stream, semester_code):
    """
    Parses East West University Exam Schedule PDF.
    PDF usually has a table with these columns:
    Class Days | Last Day of Classes | Final Exam Day | Final Exam Date
    """
    exams = []
    
    with pdfplumber.open(pdf_stream) as pdf:
        for page in pdf.pages:
            tables = page.extract_tables()
            if not tables:
                logging.warning(f"No tables found on page {page.page_number}")
                continue
                
            for table in tables:
                if not table: continue
                
                # Identify header
                for row in table:
                    # Clean the row
                    clean_row = [str(x).strip() if x else "" for x in row]
                    
                    # Skip empty rows or rows that don't look like data
                    if not any(clean_row): continue
                    
                    # Normalize text and join for pattern check
                    row_text = " ".join(clean_row).lower()
                    
                    # Skip header rows
                    if "class days" in row_text or "final exam" in row_text:
                        continue
                    
                    # Log row for debugging if needed
                    logging.debug(f"Parsing exam row: {clean_row}")
                    
                    # Expecting exactly 4 columns based on current format
                    if len(clean_row) < 4:
                        continue
                    
                    class_days = clean_row[0]
                    last_class_date = clean_row[1]
                    exam_day = clean_row[2]
                    exam_date = clean_row[3]
                    
                    # Skip rows that are clearly not data (e.g., footers, footnotes)
                    if not class_days or "earmarked" in row_text:
                        continue
                        
                    exams.append({
                        "class_days": class_days,
                        "last_class_date": last_class_date,
                        "exam_day": exam_day,
                        "exam_date": exam_date,
                        "semester": semester_code,
                        "type": "EXAM_SCHEDULE"
                    })
                    
    return exams
