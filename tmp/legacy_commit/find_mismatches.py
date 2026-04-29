import psycopg2
import pdfplumber
import re

DATABASE_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def get_pdf_courses():
    pdf_path = r"C:\Users\Farzana Safa\Downloads\Educational Resource Management (1).pdf"
    phrm_courses = {}
    try:
        with pdfplumber.open(pdf_path) as pdf:
            text = ""
            for i, page in enumerate(pdf.pages):
                text += page.extract_text() + "\n"
            
            matches = re.findall(r"(PHRM\w+(-L)?):.*?\nCredits:\s*(\d+(\.\d+)?)", text, re.I | re.M)
            for match in matches:
                code = match[0].upper()
                credits = match[2]
                phrm_courses[code] = float(credits)
        return phrm_courses
    except Exception as e:
        print(f"Error reading PDF: {e}")
        return {}

def main():
    pdf_courses = get_pdf_courses()
    if not pdf_courses:
        return

    try:
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        # Get current metadata for PHRM courses
        cur.execute("SELECT code, credit_val FROM course_metadata WHERE code LIKE 'PHRM%'")
        db_rows = cur.fetchall()
        db_courses = {row[0]: (float(row[1]) if row[1] else 0.0) for row in db_rows}
        
        mismatches = []
        for pdf_code, pdf_credit in pdf_courses.items():
            # Possible DB codes: 
            # 1. Exact match (PHRM7XYZ)
            # 2. Mapped match (PHRMXYZ) if pdf_code is 7000-series
            target_codes = [pdf_code]
            if pdf_code.startswith("PHRM7") and len(pdf_code) >= 8:
                mapped_code = "PHRM" + pdf_code[5:]
                target_codes.append(mapped_code)
            
            for code in target_codes:
                if code in db_courses:
                    db_credit_val = db_courses[code]
                    if abs(db_credit_val - pdf_credit) > 0.001:
                        mismatches.append({
                            'code': code,
                            'pdf_credit': pdf_credit,
                            'db_credit_val': db_credit_val,
                            'source': pdf_code
                        })
                else:
                    # Optional: Report missing courses if needed
                    pass
        
        if not mismatches:
            print("No mismatches found with mapping logic!")
        else:
            print(f"Found {len(mismatches)} mismatches:")
            print(f"{'Code':<15} | {'PDF':<5} | {'DB Val':<10} | {'Source'}")
            print("-" * 55)
            for m in mismatches:
                print(f"{m['code']:<15} | {m['pdf_credit']:<5} | {m['db_credit_val']:<10} | {m['source']}")
                
    except Exception as e:
        print(f"Database error: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()
