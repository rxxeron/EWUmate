
import pdfplumber
import os
import sys

print(f"Python version: {sys.version}")
cwd = os.getcwd()
print(f"Current Working Directory: {cwd}")

pdf_name = "Adviding Schedule Spring 2026.pdf"
pdf_path = os.path.join(cwd, pdf_name)
output_name = "advising_debug.txt"
output_path = os.path.join(cwd, output_name)

print(f"Checking for PDF at: {pdf_path}")
if not os.path.exists(pdf_path):
    print("PDF NOT FOUND")
    sys.exit(1)
else:
    print(f"PDF FOUND, size: {os.path.getsize(pdf_path)} bytes")
    try:
        with pdfplumber.open(pdf_path) as pdf:
            print(f"Total Pages: {len(pdf.pages)}")
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(f"Total Pages: {len(pdf.pages)}\n")
                for i, page in enumerate(pdf.pages[:5]): # Check first 5 pages
                    print(f"Processing Page {i+1}...")
                    f.write(f"--- PAGE {i+1} CONTENT ---\n")
                    text = page.extract_text()
                    f.write(text if text else "[NO TEXT]")
                    f.write("\n----------------------\n")
                    
                    tables = page.extract_tables()
                    if tables:
                        f.write(f"Found {len(tables)} tables on page {i+1}.\n")
                        for j, table in enumerate(tables):
                            f.write(f"Table {j}:\n")
                            for row in table: 
                                f.write(str(row) + "\n")
                            f.write("\n")
        print(f"Done writing to {output_path}")
        print(f"Output file size: {os.path.getsize(output_path)} bytes")
    except Exception as e:
        print(f"CRITICAL ERROR: {e}")
        sys.exit(1)
