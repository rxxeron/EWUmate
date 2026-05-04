import pdfplumber
import re

def main():
    pdf_path = r"C:\Users\Farzana Safa\Downloads\Educational Resource Management (1).pdf"
    phrm_courses = {}
    try:
        with pdfplumber.open(pdf_path) as pdf:
            text = ""
            for i, page in enumerate(pdf.pages):
                text += page.extract_text() + "\n"
            
            # Broaden pattern to find any PHRM course
            # Matches "PHRM" followed by digits, then optional characters, colon, then name, then Credits: value
            matches = re.findall(r"(PHRM\s*\d+\w*(-L)?):.*?\nCredits:\s*(\d+(\.\d+)?)", text, re.I | re.M)
            for match in matches:
                # Remove spaces from code
                code = match[0].replace(" ", "").upper()
                credits = match[2]
                phrm_courses[code] = float(credits)
                
        print(f"Total PHRM courses found in PDF: {len(phrm_courses)}")
        for code, credits in sorted(phrm_courses.items()):
            print(f"{code}: {credits}")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
