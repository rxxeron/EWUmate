
import pdfplumber

pdf_path = "Adviding Schedule Spring 2026.pdf"

with pdfplumber.open(pdf_path) as pdf:
    for i, page in enumerate(pdf.pages):
        print(f"Page {i+1}:")
        print(f"  Images: {len(page.images)}")
        print(f"  Text length: {len(page.extract_text() or '')}")
        print(f"  Tables: {len(page.extract_tables())}")
