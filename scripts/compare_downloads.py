import json
import psycopg2

def load_json(filepath, encoding='utf-8'):
    try:
        with open(filepath, 'r', encoding=encoding) as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading {filepath}: {e}")
        return []

def normalize_code(code):
    if not code:
        return ""
    return str(code).strip().upper()

def generate_report():
    file1 = r"C:\Users\Farzana Safa\Downloads\New folder (2)\courses_parsed_2.json"
    file2 = r"C:\Users\Farzana Safa\Downloads\New folder (2)\courses.json"
    
    data1 = load_json(file1)
    data2 = load_json(file2)
    
    combined_data = {}
    
    for item in data1 + data2:
        code = normalize_code(item.get("Course Code") or item.get("code") or item.get("course_code"))
        if not code:
            continue
            
        name = item.get("Course Name") or item.get("name") or item.get("course_name")
        credit = item.get("Credits") or item.get("credit") or item.get("credits")
        equiv = item.get("Equivalence Code") or item.get("equivalent_code") or item.get("equiv_code")
        
        try:
            credit = float(credit) if credit is not None else 3.0
        except ValueError:
            credit = 3.0
            
        if not equiv or str(equiv).strip() == "":
            equiv = None
            
        combined_data[code] = {
            "code": code,
            "name": str(name).strip() if name else "",
            "credit_val": credit,
            "equivalent_code": normalize_code(equiv) if equiv else None
        }

    try:
        conn = psycopg2.connect("postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres")
        cur = conn.cursor()
        
        cur.execute("SELECT code, name, credit_val, equivalent_code FROM course_metadata;")
        existing_courses = cur.fetchall()
        
        db_metadata = {
            row[0].strip().upper(): {
                "name": str(row[1]).strip() if row[1] else "",
                "credit_val": float(row[2]) if row[2] is not None else 3.0,
                "equivalent_code": str(row[3]).strip().upper() if row[3] else None
            } for row in existing_courses
        }
        
        to_insert = []
        to_update = []
        
        for code, data in combined_data.items():
            if code not in db_metadata:
                to_insert.append(data)
            else:
                db_data = db_metadata[code]
                changes = []
                
                # Check for changes
                if data["name"] and data["name"].lower() != db_data["name"].lower():
                    changes.append(f"Name: '{db_data['name']}' -> '{data['name']}'")
                
                if data["credit_val"] != db_data["credit_val"]:
                    changes.append(f"Credit: {db_data['credit_val']} -> {data['credit_val']}")
                    
                if data["equivalent_code"] and data["equivalent_code"] != db_data["equivalent_code"]:
                    changes.append(f"Equiv: '{db_data['equivalent_code']}' -> '{data['equivalent_code']}'")
                    
                if changes:
                    to_update.append({
                        "code": code,
                        "changes": ", ".join(changes)
                    })
                    
        cur.close()
        conn.close()
        
        with open("comparison_report.md", "w", encoding="utf-8") as f:
            f.write("# Course Metadata Comparison Report\n\n")
            f.write(f"**Loaded unique courses from JSON:** {len(combined_data)}\n")
            f.write(f"**Loaded courses from DB:** {len(db_metadata)}\n\n")
            
            f.write(f"## New Courses to Insert ({len(to_insert)})\n")
            if to_insert:
                f.write("| Course Code | Course Name | Credits | Equiv Code |\n")
                f.write("|-------------|-------------|---------|------------|\n")
                for item in to_insert:
                    f.write(f"| {item['code']} | {item['name']} | {item['credit_val']} | {item['equivalent_code'] or 'N/A'} |\n")
            else:
                f.write("*No new courses found.*\n")
                
            f.write(f"\n## Existing Courses with Updates ({len(to_update)})\n")
            if to_update:
                f.write("| Course Code | Changes |\n")
                f.write("|-------------|---------|\n")
                for item in to_update:
                    f.write(f"| {item['code']} | {item['changes']} |\n")
            else:
                f.write("*No updates needed for existing courses.*\n")
                
        print("Report successfully written to comparison_report.md")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    generate_report()
