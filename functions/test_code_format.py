import re
import pdfplumber

pdf_path = r"C:\Users\ibnea\Downloads\Mobile App\Mobile App\flutter_v2_new\Updated_Faculty_List_Spring-26.2026-01-15.20-07-05.pdf"
line_pattern = re.compile(r"^([A-Z]{2,4}\d{3,4}[A-Z]?)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)$")

with pdfplumber.open(pdf_path) as pdf:
    for i in range(5): # Check first 5 pages
        page = pdf.pages[i]
        text = page.extract_text()
        if not text: continue
        lines = text.split('\n')
        for line in lines:
            match = line_pattern.match(line)
            if match:
                print(f"Captured Code: '{match.group(1)}'")
                break
        else:
            continue
        break
