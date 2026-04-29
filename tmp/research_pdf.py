import pdfplumber

pdf_path = r"C:\Users\Farzana Safa\Downloads\ewuundergraduate-bulletin-14th-edition-doc-version.pdf"

def extract_sample(start_page, end_page):
    with pdfplumber.open(pdf_path) as pdf:
        for i in range(start_page - 1, min(len(pdf.pages), end_page)):
            page = pdf.pages[i]
            print(f"--- Page {i+1} ---")
            text = page.extract_text()
            if text:
                print(text)
            else:
                print("[No text found]")
            
            # Extract tables too just in case
            tables = page.extract_tables()
            if tables:
                print(f"[Found {len(tables)} tables]")
                for table in tables:
                    print(table)

if __name__ == "__main__":
    # Sample first few pages of the requested range
    extract_sample(229, 235)
