import json
import re
from collections import Counter, defaultdict
from pathlib import Path

import pdfplumber

PDF_PATHS = [
    r"C:\Users\Farzana Safa\Downloads\Educational Resource Management.pdf",
    r"C:\Users\Farzana Safa\Downloads\Educational Resource Management (1).pdf",
    r"C:\Users\Farzana Safa\Downloads\Educational Resource Management (2).PDF",
    r"C:\Users\Farzana Safa\Downloads\Educational Resource Management (3).pdf",
]

OUTPUT_JSON = Path("pdf_course_extraction_strict.json")
ALLOWED_CREDITS = {3.0, 4.0, 4.5, 6.0, 8.0}

CODE_RE = re.compile(r"\b([A-Z]{2,4})\s*-?\s*(\d{3}[A-Z]?)\b")
CREDIT_RE = re.compile(r"^\s*(\d+(?:\.\d+)?)\s*$")
SKIP_ROW_HINTS = ("course description", "prerequisites", "total credits")


def ws(text: str) -> str:
    return " ".join((text or "").replace("\n", " ").split())


def extract_codes(text: str):
    return [f"{a}{b}" for a, b in CODE_RE.findall((text or "").upper())]


def parse_credit(cell: str):
    m = CREDIT_RE.match(cell or "")
    if not m:
        return None
    val = float(m.group(1))
    if 0.0 <= val <= 10.0:
        return val
    return None


def score_name(name: str):
    # Prefer mostly alphabetic names with low digit noise.
    if not name:
        return -10
    digits = sum(ch.isdigit() for ch in name)
    letters = sum(ch.isalpha() for ch in name)
    if letters == 0:
        return -10
    return letters - (digits * 2)


def normalized_header(row):
    return [ws(c).lower() for c in (row or [])]


def has_curriculum_header(header):
    text = " | ".join(header)
    return ("course code" in text) and ("course name" in text) and ("credit" in text)


def has_equivalent_header(header):
    text = " | ".join(header)
    return ("equi" in text or "equivalent" in text) and ("course name" in text) and ("credit" in text)


def find_col_idx(header, key):
    for i, h in enumerate(header):
        if key in h:
            return i
    return None


def parse_curriculum_row(row, header, source):
    cells = [ws(c) for c in row]
    if not any(cells):
        return None
    row_text = " | ".join(cells).lower()
    if any(hint in row_text for hint in SKIP_ROW_HINTS):
        return None

    code_idx = find_col_idx(header, "course code")
    name_idx = find_col_idx(header, "course name")
    credit_idx = find_col_idx(header, "credit")
    if code_idx is None or name_idx is None or credit_idx is None:
        return None

    code_cell = cells[code_idx] if code_idx < len(cells) else ""
    name_cell = cells[name_idx] if name_idx < len(cells) else ""
    credit_cell = cells[credit_idx] if credit_idx < len(cells) else ""

    codes = extract_codes(code_cell)
    if not codes:
        # Fallback for merged cells where code is embedded in name.
        codes = extract_codes(name_cell)
    if not codes:
        return None

    return {
        "course_code": codes[0],
        "name_candidates": [name_cell] if name_cell else [],
        "credit": parse_credit(credit_cell),
        "equivalence": [],
        "source": source,
    }


def parse_equivalent_row(row, header, source):
    cells = [ws(c) for c in row]
    if not any(cells):
        return []
    row_text = " | ".join(cells).lower()
    if any(hint in row_text for hint in SKIP_ROW_HINTS):
        return []

    src_idx = find_col_idx(header, "course name")
    eq_idx = find_col_idx(header, "equi")
    credit_idx = find_col_idx(header, "credit")
    if src_idx is None or eq_idx is None:
        return []

    src_cell = cells[src_idx] if src_idx < len(cells) else ""
    eq_cell = cells[eq_idx] if eq_idx < len(cells) else ""
    credit_cell = cells[credit_idx] if (credit_idx is not None and credit_idx < len(cells)) else ""

    src_codes = extract_codes(src_cell)
    eq_codes = extract_codes(eq_cell)
    if not src_codes and not eq_codes:
        return []

    credit = parse_credit(credit_cell)
    records = []
    for src_code in src_codes:
        records.append(
            {
                "course_code": src_code,
                "name_candidates": [src_cell],
                "credit": credit,
                "equivalence": [c for c in eq_codes if c != src_code],
                "source": source,
            }
        )
    return records


def extract_from_row(row, source):
    cells = [ws(c) for c in row]
    row_codes = []
    for c in cells:
        row_codes.extend(extract_codes(c))
    row_codes = list(dict.fromkeys(row_codes))
    if not row_codes:
        return []

    main_code = row_codes[0]
    eq_codes = [c for c in row_codes[1:] if c != main_code]

    # Name: first non-code, non-credit text cell after main code cell.
    name_candidates = []
    main_idx = 0
    for i, c in enumerate(cells):
        if main_code in extract_codes(c):
            main_idx = i
            break

    for i, c in enumerate(cells):
        if not c:
            continue
        if i == main_idx:
            continue
        if extract_codes(c):
            continue
        if parse_credit(c) is not None:
            continue
        if len(c) < 3:
            continue
        name_candidates.append(c)

    # Credit: choose numeric cell closest to the main code cell.
    credit = None
    numeric_cells = []
    for i, c in enumerate(cells):
        val = parse_credit(c)
        if val is not None:
            numeric_cells.append((abs(i - main_idx), val))
    if numeric_cells:
        numeric_cells.sort(key=lambda x: x[0])
        credit = numeric_cells[0][1]

    return [
        {
            "course_code": main_code,
            "name_candidates": name_candidates,
            "credit": credit,
            "equivalence": eq_codes,
            "source": source,
        }
    ]


def main():
    records = []

    for p in PDF_PATHS:
        pdf_path = Path(p)
        if not pdf_path.exists():
            print(f"[WARN] Missing file: {pdf_path}")
            continue

        with pdfplumber.open(str(pdf_path)) as pdf:
            for page_num, page in enumerate(pdf.pages, start=1):
                source = f"{pdf_path.name}#page-{page_num}"
                tables = page.extract_tables() or []
                for table in tables:
                    if not table:
                        continue

                    header = normalized_header(table[0])
                    if has_curriculum_header(header):
                        for row in table[1:]:
                            rec = parse_curriculum_row(row, header, source)
                            if rec:
                                records.append(rec)
                        continue

                    if has_equivalent_header(header):
                        for row in table[1:]:
                            records.extend(parse_equivalent_row(row, header, source))
                        continue

    # Aggregate by code.
    agg = defaultdict(lambda: {
        "name_counter": Counter(),
        "credit_counter": Counter(),
        "equivalence": Counter(),
        "sources": set(),
        "source_credits": defaultdict(Counter),
        "source_names": defaultdict(Counter),
    })

    for r in records:
        code = r["course_code"]
        a = agg[code]
        for n in r["name_candidates"]:
            a["name_counter"][n] += 1
            src_file = r["source"].split("#")[0]
            a["source_names"][src_file][n] += 1
        if r["credit"] is not None:
            a["credit_counter"][r["credit"]] += 1
            src_file = r["source"].split("#")[0]
            a["source_credits"][src_file][r["credit"]] += 1
        for e in r["equivalence"]:
            a["equivalence"][e] += 1
        a["sources"].add(r["source"])

    courses = []
    discrepancies = []

    for code in sorted(agg.keys()):
        a = agg[code]

        names_sorted = sorted(a["name_counter"].items(), key=lambda x: (-x[1], -score_name(x[0]), len(x[0])))
        credits_sorted = sorted(a["credit_counter"].items(), key=lambda x: (-x[1], x[0]))
        eq_sorted = sorted(a["equivalence"].items(), key=lambda x: (-x[1], x[0]))

        primary_name = names_sorted[0][0] if names_sorted else ""
        primary_credit = credits_sorted[0][0] if credits_sorted else None

        course = {
            "course_code": code,
            "primary_name": primary_name,
            "primary_credit": primary_credit,
            "equivalence_codes": [x[0] for x in eq_sorted],
            "name_variants": [{"value": n, "count": c} for n, c in names_sorted],
            "credit_variants": [{"value": v, "count": c} for v, c in credits_sorted],
            "source_files": sorted({s.split("#")[0] for s in a["sources"]}),
            "source_credit_variants": {
                src: [{"value": v, "count": c} for v, c in sorted(cnt.items(), key=lambda x: (-x[1], x[0]))]
                for src, cnt in a["source_credits"].items()
            },
        }
        courses.append(course)

        issues = []
        credit_values = [x["value"] for x in course["credit_variants"]]
        if len(credit_values) > 1:
            issues.append("credit_mismatch")
        if primary_credit is None:
            issues.append("missing_credit")
        elif primary_credit not in ALLOWED_CREDITS:
            issues.append("credit_not_in_allowed_set")
        if len(course["name_variants"]) > 1:
            issues.append("name_mismatch")
        if len(course["equivalence_codes"]) > 1:
            issues.append("equivalence_variation")

        # Cross-file credit inconsistency.
        file_top_credits = []
        for src, vals in course["source_credit_variants"].items():
            if vals:
                file_top_credits.append(vals[0]["value"])
        if len(set(file_top_credits)) > 1 and "credit_mismatch" not in issues:
            issues.append("credit_mismatch")

        if issues:
            discrepancies.append(
                {
                    "course_code": code,
                    "issues": issues,
                    "primary_name": primary_name,
                    "primary_credit": primary_credit,
                    "credit_variants": course["credit_variants"],
                    "name_variants": course["name_variants"][:5],
                    "equivalence_codes": course["equivalence_codes"],
                }
            )

    output = {
        "pdfs": PDF_PATHS,
        "parsing_mode": "header_driven_curriculum_and_equivalent_tables_only",
        "total_rows_extracted": len(records),
        "total_unique_courses": len(courses),
        "allowed_credits": sorted(ALLOWED_CREDITS),
        "courses": courses,
        "discrepancies": discrepancies,
        "discrepancy_count": len(discrepancies),
    }

    OUTPUT_JSON.write_text(json.dumps(output, indent=2), encoding="utf-8")
    print(f"Wrote {OUTPUT_JSON} | unique_courses={len(courses)} discrepancies={len(discrepancies)}")


if __name__ == "__main__":
    main()
