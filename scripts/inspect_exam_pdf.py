import pdfplumber

pdf_path = r"C:\Users\ibnea\Downloads\Mobile App\Mobile App\flutter_v2_new\694258f5656d7153021981.pdf"

with pdfplumber.open(pdf_path) as pdf:
    print(f"Total Pages: {len(pdf.pages)}")
    if len(pdf.pages) > 0:
        page = pdf.pages[0]
        print("--- First Page Text ---")
        print(page.extract_text())
        print("\n--- First Page Tables ---")
        tables = page.extract_tables()
        if tables:
            for i, table in enumerate(tables):
                print(f"Table {i}:")
                for row in table[:10]: # Print first 10 rows
                    # clean output
                    clean_row = [str(x).strip() if x else "" for x in row]
                    print(f"Row {i}: | " + " | ".join(clean_row) + " |")
        else:
            print("No tables found.")
