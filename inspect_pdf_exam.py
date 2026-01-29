
import pdfplumber
import os

pdf_path = os.path.join(os.getcwd(), 'Exam Spring 2026.pdf')

with pdfplumber.open(pdf_path) as pdf:
    for i, page in enumerate(pdf.pages):
        print(f"--- Page {i+1} ---")
        st = page.extract_text()
        print("Raw Text:")
        print(st[:1000] if st else "No text found")
        print("-" * 20)
        
        tables = page.extract_tables()
        print(f"Tables found: {len(tables)}")
        for j, table in enumerate(tables):
            print(f"Table {j+1}:")
            for row in table:
                print(row)
            print("." * 10)
