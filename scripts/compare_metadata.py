import json
import os

def load_json(filepath, encoding='utf-8'):
    try:
        with open(filepath, 'r', encoding=encoding) as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading {filepath}: {e}")
        return None

def normalize_code(code):
    if not code:
        return ""
    # Strip name prefix if present (e.g., "ENG101: Basic English" -> "ENG101")
    if ":" in code:
        return code.split(":")[0].strip()
    return str(code).strip()

def run_comparison():
    merged_path = 'merged_courses_cleaned.json'
    metadata_path = 'course_metadata_full.json'
    
    merged_data = load_json(merged_path, 'utf-8')
    metadata_data = load_json(metadata_path, 'utf-16')
    
    if not merged_data or not metadata_data:
        return

    # Convert metadata to a dictionary for fast lookup
    metadata_lookup = {normalize_code(m['code']): m for m in metadata_data}
    
    discrepancies = {
        'missing_from_metadata': [],
        'credit_mismatches': [],
        'name_mismatches': [],
        'duplicates_in_merged': [],
        'non_standard_codes': []
    }
    
    seen_codes = set()
    
    for entry in merged_data:
        raw_code = entry.get('Code')
        if not raw_code:
            continue
            
        code = normalize_code(raw_code)
        if ":" in raw_code:
            discrepancies['non_standard_codes'].append({'raw': raw_code, 'normalized': code})
            
        if code in seen_codes:
            discrepancies['duplicates_in_merged'].append(code)
        seen_codes.add(code)
        
        if code not in metadata_lookup:
            discrepancies['missing_from_metadata'].append({
                'code': code,
                'name': entry.get('Name'),
                'credit': entry.get('Credit')
            })
        else:
            meta = metadata_lookup[code]
            
            # Check credits
            try:
                merged_credit = float(entry.get('Credit', 0))
                meta_credit = float(meta.get('credit_val', 0))
                if merged_credit != meta_credit:
                    discrepancies['credit_mismatches'].append({
                        'code': code,
                        'merged': merged_credit,
                        'metadata': meta_credit
                    })
            except ValueError:
                pass
                
            # Check names (soft check)
            merged_name = str(entry.get('Name', '')).lower().strip()
            meta_name = str(meta.get('name', '')).lower().strip()
            if merged_name != meta_name:
                # Basic check to avoid trivial differences
                if merged_name and meta_name and merged_name not in meta_name and meta_name not in merged_name:
                    discrepancies['name_mismatches'].append({
                        'code': code,
                        'merged': entry.get('Name'),
                        'metadata': meta.get('name')
                    })

    # Writing report
    with open('reconciliation_report.md', 'w', encoding='utf-8') as f:
        f.write("# Course Metadata Reconciliation Report\n\n")
        
        f.write("## Summary Statistics\n")
        f.write(f"- Total in Cleaned: {len(merged_data)}\n")
        f.write(f"- Total in Metadata: {len(metadata_data)}\n")
        f.write(f"- Distinct Codes in Cleaned: {len(seen_codes)}\n\n")
        
        f.write("## 1. Missing from Metadata\n")
        if not discrepancies['missing_from_metadata']:
            f.write("None\n")
        else:
            f.write("| Code | Name | Credit |\n|---|---|---|\n")
            for item in discrepancies['missing_from_metadata'][:50]: # Limit to 50
                f.write(f"| {item['code']} | {item['name']} | {item['credit']} |\n")
            if len(discrepancies['missing_from_metadata']) > 50:
                f.write(f"\n... and {len(discrepancies['missing_from_metadata']) - 50} more.\n")
        
        f.write("\n## 2. Credit Mismatches\n")
        if not discrepancies['credit_mismatches']:
            f.write("None\n")
        else:
            f.write("| Code | Cleaned Credit | Metadata Credit |\n|---|---|---|\n")
            for item in discrepancies['credit_mismatches']:
                f.write(f"| {item['code']} | {item['merged']} | {item['metadata']} |\n")
                
        f.write("\n## 3. Duplicates in Cleaned\n")
        if not discrepancies['duplicates_in_merged']:
            f.write("None\n")
        else:
            f.write(", ".join(set(discrepancies['duplicates_in_merged'])) + "\n")
            
        f.write("\n## 4. Non-Standard Codes Found\n")
        if not discrepancies['non_standard_codes']:
            f.write("None\n")
        else:
            f.write("| Raw Code | Normalized |\n|---|---|\n")
            for item in discrepancies['non_standard_codes'][:20]:
                f.write(f"| {item['raw']} | {item['normalized']} |\n")

    print("Report generated: reconciliation_report.md")

if __name__ == "__main__":
    run_comparison()
