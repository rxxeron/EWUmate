import pdfplumber

def main():
    pdf_path = r"C:\Users\Farzana Safa\Downloads\Educational Resource Management (1).pdf"
    with pdfplumber.open(pdf_path) as pdf:
        with open("pdf_text.txt", "w", encoding="utf-8") as f:
            for page in pdf.pages:
                f.write(page.extract_text() + "\n")

if __name__ == "__main__":
    main()
