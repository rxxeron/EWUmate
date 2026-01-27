
import pdfplumber
import os

pdf_path = os.path.join(os.getcwd(), 'Credit and CGPA requirements for Scholarships.pdf')
output_path = os.path.join(os.getcwd(), 'scholarship_requirements.txt')

def clean_text(text):
    if not text:
        return ""
    return text.replace('\x00', '')

def format_row(row):
    # Convert None to empty string and replace newlines with spaces for cleaner checking
    clean_row = [str(cell).replace('\n', ' ') if cell is not None else "" for cell in row]
    return " | ".join(clean_row)

print(f"Parsing {pdf_path}...")

with open(output_path, 'w', encoding='utf-8') as f:
    try:
        with pdfplumber.open(pdf_path) as pdf:
            for i, page in enumerate(pdf.pages):
                f.write(f"=== Page {i+1} ===\n\n")
                
                # Extract words to try to maintain layout? Text extraction usually sufficient for flowing text
                text = page.extract_text()
                if text:
                    f.write("--- Content ---\n")
                    f.write(clean_text(text))
                    f.write("\n\n")
                
                # Extract tables with better formatting
                tables = page.extract_tables()
                if tables:
                    f.write(f"--- Tables ({len(tables)}) ---\n")
                    for t_idx, table in enumerate(tables):
                        f.write(f"Table {t_idx+1}:\n")
                        # Calculate column widths (basic)
                        if not table: continue
                        
                        f.write("-" * 50 + "\n")
                        for row in table:
                            f.write(format_row(row) + "\n")
                        f.write("-" * 50 + "\n\n")
                
                f.write("\n")
                
        print(f"Successfully generated {output_path}")
    except Exception as e:
        print(f"Error parsing PDF: {e}")
