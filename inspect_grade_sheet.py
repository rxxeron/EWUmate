
import pdfplumber
import os

pdf_path = os.path.join(os.getcwd(), 'GradeSheetIndividualStudent.pdf')
output_path = os.path.join(os.getcwd(), 'grade_sheet_content.txt')

print(f"Inspecting {pdf_path}...")

with open(output_path, 'w', encoding='utf-8') as f:
    with pdfplumber.open(pdf_path) as pdf:
        for i, page in enumerate(pdf.pages):
            f.write(f"--- Page {i+1} ---\n")
            
            # Text extraction
            text = page.extract_text()
            if text:
                f.write("RAW TEXT:\n")
                f.write(text)
                f.write("\n\n")
            
            # Table extraction
            tables = page.extract_tables()
            if tables:
                f.write(f"TABLES ({len(tables)}):\n")
                for j, table in enumerate(tables):
                    f.write(f"Table {j+1}:\n")
                    for row in table:
                        f.write(str(row) + "\n")
                    f.write("\n")
            f.write("-" * 30 + "\n")

print(f"Content saved to {output_path}")
