import json
import pdfplumber
from pathlib import Path

PDF_PATHS = [
    r"C:\Users\Farzana Safa\Downloads\Educational Resource Management (1).pdf",
]

# Output to courselist_1_equiv_cleaned.json in the main ewumate_v2 folder
OUTPUT_JSON = Path("courselist_1_equiv_cleaned.json")

def main():
    rows = []
    for pdf_path in PDF_PATHS:
        pdf_file = Path(pdf_path)
        if not pdf_file.exists():
            print(f"[WARN] Missing file: {pdf_file}")
            continue
        with pdfplumber.open(str(pdf_file)) as pdf:
            parsing_equiv = False
            found_desc = False
            for page_idx, page in enumerate(pdf.pages, start=1):
                if page_idx < 3:
                    continue
                if page_idx > 5 or found_desc:
                    break
                page_text = page.extract_text() or ""
                if "Course Description" in page_text:
                    found_desc = True
                    break
                if "Equivalent Courses" in page_text:
                    parsing_equiv = True
                if parsing_equiv and not found_desc:
                    for table in page.extract_tables() or []:
                        for row in table or []:
                            if len(row) < 4:
                                continue
                            # Split code and name for both columns
                            def split_code_name(val):
                                parts = str(val).split(":", 1)
                                if len(parts) == 2:
                                    return parts[0].strip(), parts[1].strip()
                                return str(val).strip(), ""
                            course_code, name = split_code_name(row[1])
                            equivalence_code, _ = split_code_name(row[2])
                            rows.append({
                                "course_code": course_code,
                                "name": name,
                                "equivalence_code": equivalence_code,
                                "credit": row[3]
                            })
    OUTPUT_JSON.write_text(json.dumps(rows, indent=2), encoding="utf-8")
    print(f"Wrote {OUTPUT_JSON} with {len(rows)} rows (simple table dump)")

if __name__ == "__main__":
    main()
