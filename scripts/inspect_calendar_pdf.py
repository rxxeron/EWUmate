import pdfplumber

pdf_path = r"C:\Users\ibnea\Downloads\Mobile App\Mobile App\flutter_v2_new\69424bf19d906466563612 (1).pdf"

with pdfplumber.open(pdf_path) as pdf:
    page = pdf.pages[0]
    tables = page.extract_tables()
    
    if tables:
        print(f"Found {len(tables)} tables.")
        table = tables[0]
        for i, row in enumerate(table[:50]):
            # Replace None with "" and join
            clean_row = [str(x) if x else "" for x in row]
            print(f"Row {i}: | " + " | ".join(clean_row) + " |")
    else:
        print("No tables found.")
