import pdfplumber

pdf_path = "../Updated_Faculty_List_Spring-26.2026-01-15.20-07-05.pdf"
with pdfplumber.open(pdf_path) as pdf:
    page = pdf.pages[0]
    width = float(page.width)
    height = float(page.height)
    
    left = page.within_bbox((0, 0, width/2, height))
    right = page.within_bbox((width/2, 0, width, height))
    
    print("--- LEFT COLUMN SAMPLE ---")
    print("\n".join(left.extract_text().split('\n')[:10]))
    print("\n--- RIGHT COLUMN SAMPLE ---")
    print("\n".join(right.extract_text().split('\n')[:10]))
