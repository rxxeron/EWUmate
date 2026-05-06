import json
import psycopg2

def compare_list():
    provided_json = """
[
    {
        "Course Name": "Basic English",
        "Credits": 3,
        "Course Code": "ENG101",
        "Equivalence Code": "ENG7101"
    },
    {
        "Course Name": "Composition and Communication Skills",
        "Credits": 3,
        "Course Code": "ENG102",
        "Equivalence Code": "ENG7102"
    },
    {
        "Course Name": "Emergence of Bangladesh",
        "Credits": 3,
        "Course Code": "GEN226",
        "Equivalence Code": "GEN7226"
    },
    {
        "Course Name": "Introduction to Computers I",
        "Credits": 3,
        "Course Code": "CSE101",
        "Equivalence Code": "CSE7101"
    },
    {
        "Course Name": "Basic Entrepreneurship",
        "Credits": 3,
        "Course Code": "EDC101",
        "Equivalence Code": "EDC7101"
    },
    {
        "Course Name": "Improving Oral Communication Skills",
        "Credits": 3,
        "Course Code": "ENG100",
        "Equivalence Code": "ENG7100"
    },
    {
        "Course Name": "Introduction to Economics",
        "Credits": 3,
        "Course Code": "GEN101",
        "Equivalence Code": "GEN7101"
    },
    {
        "Course Name": "Eastern Culture and Heritage",
        "Credits": 3,
        "Course Code": "GEN202",
        "Equivalence Code": "GEN7202"
    },
    {
        "Course Name": "Introduction to Psychology",
        "Credits": 3,
        "Course Code": "GEN205",
        "Equivalence Code": "GEN7205"
    },
    {
        "Course Name": "Industrial Psychology",
        "Credits": 3,
        "Course Code": "GEN207",
        "Equivalence Code": "GEN7207"
    },
    {
        "Course Name": "Introduction to Philosophy",
        "Credits": 3,
        "Course Code": "GEN208",
        "Equivalence Code": "GEN7208"
    },
    {
        "Course Name": "Introduction to Social Psychology",
        "Credits": 3,
        "Course Code": "GEN209",
        "Equivalence Code": "GEN7209"
    },
    {
        "Course Name": "International Relation",
        "Credits": 3,
        "Course Code": "GEN210",
        "Equivalence Code": "GEN7210"
    },
    {
        "Course Name": "Introduction to Development Studies",
        "Credits": 3,
        "Course Code": "GEN214",
        "Equivalence Code": "GEN7214"
    },
    {
        "Course Name": "Principles of Public Relations",
        "Credits": 3,
        "Course Code": "GEN220",
        "Equivalence Code": "GEN7220"
    },
    {
        "Course Name": "Professional Ethics",
        "Credits": 3,
        "Course Code": "GEN239",
        "Equivalence Code": "GEN7239"
    },
    {
        "Course Name": "Introduction to Anthropology",
        "Credits": 3,
        "Course Code": "PPHS108",
        "Equivalence Code": "PPHS7108"
    },
    {
        "Course Name": "Ecological System and Environment",
        "Credits": 3,
        "Course Code": "PPHS201",
        "Equivalence Code": "PPHS7201"
    },
    {
        "Course Name": "Media Applications for Public Health",
        "Credits": 3,
        "Course Code": "PPHS315",
        "Equivalence Code": "PPHS7315"
    },
    {
        "Course Name": "Business Demography",
        "Credits": 3,
        "Course Code": "PPHS316",
        "Equivalence Code": "PPHS7316"
    },
    {
        "Course Name": "Introduction to Population Sciences",
        "Credits": 3,
        "Course Code": "PPHS101",
        "Equivalence Code": "PPHS7101"
    },
    {
        "Course Name": "Introduction to Public Health Sciences",
        "Credits": 3,
        "Course Code": "PPHS102",
        "Equivalence Code": "PPHS7102"
    },
    {
        "Course Name": "Introduction to Environmental Health",
        "Credits": 3,
        "Course Code": "PPHS103",
        "Equivalence Code": "PPHS7103"
    },
    {
        "Course Name": "Introduction to Biostatistics",
        "Credits": 3,
        "Course Code": "PPHS104",
        "Equivalence Code": "PPHS7104"
    },
    {
        "Course Name": "Introduction to Epidemiology",
        "Credits": 3,
        "Course Code": "PPHS105",
        "Equivalence Code": "PPHS7105"
    },
    {
        "Course Name": "Introduction to Social and Behavioral Sciences",
        "Credits": 3,
        "Course Code": "PPHS106",
        "Equivalence Code": "PPHS7106"
    },
    {
        "Course Name": "Behavioral Change Communication and Health Promotion",
        "Credits": 3,
        "Course Code": "PPHS202",
        "Equivalence Code": "PPHS7202"
    },
    {
        "Course Name": "Inferential and Applied Statistics",
        "Credits": 3,
        "Course Code": "PPHS203",
        "Equivalence Code": "PPHS7203"
    },
    {
        "Course Name": "Quantitative Research Methodology",
        "Credits": 3,
        "Course Code": "PPHS204",
        "Equivalence Code": "PPHS7204"
    },
    {
        "Course Name": "Quantitative Data Analysis Using Software, Tools and Report Writing",
        "Credits": 3,
        "Course Code": "PPHS205",
        "Equivalence Code": "PPHS7205"
    },
    {
        "Course Name": "Advanced Epidemiology",
        "Credits": 3,
        "Course Code": "PPHS306",
        "Equivalence Code": "PPHS7306"
    },
    {
        "Course Name": "Qualitative Research Methodology",
        "Credits": 3,
        "Course Code": "PPHS307",
        "Equivalence Code": "PPHS7307"
    },
    {
        "Course Name": "Qualitative Data Analysis using Software, Tools and Report Writing",
        "Credits": 3,
        "Course Code": "PPHS408",
        "Equivalence Code": "PPHS7408"
    },
    {
        "Course Name": "Project Planning, Monitoring and Evaluation",
        "Credits": 3,
        "Course Code": "PPHS409",
        "Equivalence Code": "PPHS7409"
    },
    {
        "Course Name": "Global Environmental Challenges",
        "Credits": 3,
        "Course Code": "EHS301",
        "Equivalence Code": "EHS7301"
    },
    {
        "Course Name": "Environmental Health",
        "Credits": 3,
        "Course Code": "EHS302",
        "Equivalence Code": "EHS7302"
    },
    {
        "Course Name": "Disaster Risk Reduction and Climate Change Adaptation in Bangladesh",
        "Credits": 3,
        "Course Code": "EHS303",
        "Equivalence Code": "EHS7303"
    },
    {
        "Course Name": "Environment and Development",
        "Credits": 3,
        "Course Code": "EHS304",
        "Equivalence Code": "EHS7304"
    },
    {
        "Course Name": "Gender and Environment",
        "Credits": 3,
        "Course Code": "EHS305",
        "Equivalence Code": "EHS7305"
    },
    {
        "Course Name": "Climate Change and Human Health",
        "Credits": 3,
        "Course Code": "EHS306",
        "Equivalence Code": "EHS7306"
    },
    {
        "Course Name": "Environmental Pollution and Human Health",
        "Credits": 3,
        "Course Code": "EHS307",
        "Equivalence Code": "EHS7307"
    },
    {
        "Course Name": "Environmental Health in Emergencies",
        "Credits": 3,
        "Course Code": "EHS401",
        "Equivalence Code": "EHS7401"
    },
    {
        "Course Name": "Urbanization and Sustainable Cities",
        "Credits": 3,
        "Course Code": "EHS402",
        "Equivalence Code": "EHS7402"
    },
    {
        "Course Name": "Food Security , Public Health and the Environment",
        "Credits": 3,
        "Course Code": "EHS403",
        "Equivalence Code": "EHS7403"
    },
    {
        "Course Name": "Environmental Epidemiology",
        "Credits": 3,
        "Course Code": "EHS404",
        "Equivalence Code": "EHS7404"
    },
    {
        "Course Name": "Public Health Toxicology",
        "Credits": 3,
        "Course Code": "EHS405",
        "Equivalence Code": "EHS7405"
    },
    {
        "Course Name": "Spatial Analysis of Population, Health and Development",
        "Credits": 3,
        "Course Code": "EHS406",
        "Equivalence Code": "EHS7406"
    },
    {
        "Course Name": "Social Determinants of Health and Well-being",
        "Credits": 3,
        "Course Code": "PHS301",
        "Equivalence Code": "PHS7301"
    },
    {
        "Course Name": "Epidemiology of Communicable and Neglected Tropical Diseases",
        "Credits": 3,
        "Course Code": "PHS302",
        "Equivalence Code": "PHS7302"
    },
    {
        "Course Name": "Urban Health in Bangladesh",
        "Credits": 3,
        "Course Code": "PHS303",
        "Equivalence Code": "PHS7303"
    },
    {
        "Course Name": "Sexual and Reproductive Health and Rights",
        "Credits": 3,
        "Course Code": "PHS304",
        "Equivalence Code": "PHS7304"
    },
    {
        "Course Name": "Epidemiology of Non-communicable Diseases and Injuries",
        "Credits": 3,
        "Course Code": "PHS305",
        "Equivalence Code": "PHS7305"
    },
    {
        "Course Name": "Global Health",
        "Credits": 3,
        "Course Code": "PHS306",
        "Equivalence Code": "PHS7306"
    },
    {
        "Course Name": "Occupational Health",
        "Credits": 3,
        "Course Code": "PHS307",
        "Equivalence Code": "PHS7307"
    },
    {
        "Course Name": "Health Systems and Administration in Bangladesh",
        "Credits": 3,
        "Course Code": "PHS401",
        "Equivalence Code": "PHS7401"
    },
    {
        "Course Name": "Health Policy and Process",
        "Credits": 3,
        "Course Code": "PHS402",
        "Equivalence Code": "PHS7402"
    },
    {
        "Course Name": "Health Economics and Healthcare Financing",
        "Credits": 3,
        "Course Code": "PHS403",
        "Equivalence Code": "PHS7403"
    },
    {
        "Course Name": "Health informatics",
        "Credits": 3,
        "Course Code": "PHS404",
        "Equivalence Code": "PHS7404"
    },
    {
        "Course Name": "Modern Health Technologies",
        "Credits": 3,
        "Course Code": "PHS405",
        "Equivalence Code": "PHS7405"
    },
    {
        "Course Name": "Public Health in Emergencies",
        "Credits": 3,
        "Course Code": "PHS406",
        "Equivalence Code": "PHS7406"
    },
    {
        "Course Name": "Fertility and Reproductive Behavior",
        "Credits": 3,
        "Course Code": "PSS301",
        "Equivalence Code": "PSS7301"
    },
    {
        "Course Name": "Mortality and Morbidity",
        "Credits": 3,
        "Course Code": "PSS302",
        "Equivalence Code": "PSS7302"
    },
    {
        "Course Name": "Population Mobility and Migration",
        "Credits": 3,
        "Course Code": "PSS303",
        "Equivalence Code": "PSS7303"
    },
    {
        "Course Name": "Techniques of Population Analysis",
        "Credits": 3,
        "Course Code": "PSS304",
        "Equivalence Code": "PSS7304"
    },
    {
        "Course Name": "Population, Nutrition and Food Security",
        "Credits": 3,
        "Course Code": "PSS305",
        "Equivalence Code": "PSS7305"
    },
    {
        "Course Name": "Population Health",
        "Credits": 3,
        "Course Code": "PSS306",
        "Equivalence Code": "PSS7306"
    },
    {
        "Course Name": "Population, Poverty and Development",
        "Credits": 3,
        "Course Code": "PSS401",
        "Equivalence Code": "PSS7401"
    },
    {
        "Course Name": "Family Demography",
        "Credits": 3,
        "Course Code": "PSS402",
        "Equivalence Code": "PSS7402"
    },
    {
        "Course Name": "Population Aging",
        "Credits": 3,
        "Course Code": "PSS403",
        "Equivalence Code": "PSS7403"
    },
    {
        "Course Name": "Population Planning and Human Resource Development",
        "Credits": 3,
        "Course Code": "PSS404",
        "Equivalence Code": "PSS7404"
    },
    {
        "Course Name": "Population Dynamics of Bangladesh",
        "Credits": 3,
        "Course Code": "PSS405",
        "Equivalence Code": "PSS7405"
    },
    {
        "Course Name": "Population Policy and Programs in Bangladesh",
        "Credits": 3,
        "Course Code": "PSS406",
        "Equivalence Code": "PSS7406"
    },
    {
        "Course Name": "Global Environmental Challenges",
        "Credits": 3,
        "Course Code": "EHS301",
        "Equivalence Code": "EHS7301"
    },
    {
        "Course Name": "Environmental Health",
        "Credits": 3,
        "Course Code": "EHS302",
        "Equivalence Code": "EHS7302"
    },
    {
        "Course Name": "Disaster Risk Reduction and Climate Change Adaptation in Bangladesh",
        "Credits": 3,
        "Course Code": "EHS303",
        "Equivalence Code": "EHS7303"
    },
    {
        "Course Name": "Environment and Development",
        "Credits": 3,
        "Course Code": "EHS304",
        "Equivalence Code": "EHS7304"
    },
    {
        "Course Name": "Gender and Environment",
        "Credits": 3,
        "Course Code": "EHS305",
        "Equivalence Code": "EHS7305"
    },
    {
        "Course Name": "Climate Change and Human Health",
        "Credits": 3,
        "Course Code": "EHS306",
        "Equivalence Code": "EHS7306"
    },
    {
        "Course Name": "Environmental Pollution and Human Health",
        "Credits": 3,
        "Course Code": "EHS307",
        "Equivalence Code": "EHS7307"
    },
    {
        "Course Name": "Environmental Health in Emergencies",
        "Credits": 3,
        "Course Code": "EHS401",
        "Equivalence Code": "EHS7401"
    },
    {
        "Course Name": "Urbanization and Sustainable Cities",
        "Credits": 3,
        "Course Code": "EHS402",
        "Equivalence Code": "EHS7402"
    },
    {
        "Course Name": "Food Security , Public Health and the Environment",
        "Credits": 3,
        "Course Code": "EHS403",
        "Equivalence Code": "EHS7403"
    },
    {
        "Course Name": "Environmental Epidemiology",
        "Credits": 3,
        "Course Code": "EHS404",
        "Equivalence Code": "EHS7404"
    },
    {
        "Course Name": "Public Health Toxicology",
        "Credits": 3,
        "Course Code": "EHS405",
        "Equivalence Code": "EHS7405"
    },
    {
        "Course Name": "Spatial Analysis of Population, Health and Development",
        "Credits": 3,
        "Course Code": "EHS406",
        "Equivalence Code": "EHS7406"
    },
    {
        "Course Name": "Social Determinants of Health and Well-being",
        "Credits": 3,
        "Course Code": "PHS301",
        "Equivalence Code": "PHS7301"
    },
    {
        "Course Name": "Epidemiology of Communicable and Neglected Tropical Diseases",
        "Credits": 3,
        "Course Code": "PHS302",
        "Equivalence Code": "PHS7302"
    },
    {
        "Course Name": "Urban Health in Bangladesh",
        "Credits": 3,
        "Course Code": "PHS303",
        "Equivalence Code": "PHS7303"
    },
    {
        "Course Name": "Sexual and Reproductive Health and Rights",
        "Credits": 3,
        "Course Code": "PHS304",
        "Equivalence Code": "PHS7304"
    },
    {
        "Course Name": "Epidemiology of Non-communicable Diseases and Injuries",
        "Credits": 3,
        "Course Code": "PHS305",
        "Equivalence Code": "PHS7305"
    },
    {
        "Course Name": "Global Health",
        "Credits": 3,
        "Course Code": "PHS306",
        "Equivalence Code": "PHS7306"
    },
    {
        "Course Name": "Occupational Health",
        "Credits": 3,
        "Course Code": "PHS307",
        "Equivalence Code": "PHS7307"
    },
    {
        "Course Name": "Health Systems and Administration in Bangladesh",
        "Credits": 3,
        "Course Code": "PHS401",
        "Equivalence Code": "PHS7401"
    },
    {
        "Course Name": "Health Policy and Process",
        "Credits": 3,
        "Course Code": "PHS402",
        "Equivalence Code": "PHS7402"
    },
    {
        "Course Name": "Health Economics and Healthcare Financing",
        "Credits": 3,
        "Course Code": "PHS403",
        "Equivalence Code": "PHS7403"
    },
    {
        "Course Name": "Health informatics",
        "Credits": 3,
        "Course Code": "PHS404",
        "Equivalence Code": "PHS7404"
    },
    {
        "Course Name": "Modern Health Technologies",
        "Credits": 3,
        "Course Code": "PHS405",
        "Equivalence Code": "PHS7405"
    },
    {
        "Course Name": "Public Health in Emergencies",
        "Credits": 3,
        "Course Code": "PHS406",
        "Equivalence Code": "PHS7406"
    },
    {
        "Course Name": "Fertility and Reproductive Behavior",
        "Credits": 3,
        "Course Code": "PSS301",
        "Equivalence Code": "PSS7301"
    },
    {
        "Course Name": "Mortality and Morbidity",
        "Credits": 3,
        "Course Code": "PSS302",
        "Equivalence Code": "PSS7302"
    },
    {
        "Course Name": "Population Mobility and Migration",
        "Credits": 3,
        "Course Code": "PSS303",
        "Equivalence Code": "PSS7303"
    },
    {
        "Course Name": "Techniques of Population Analysis",
        "Credits": 3,
        "Course Code": "PSS304",
        "Equivalence Code": "PSS7304"
    },
    {
        "Course Name": "Population, Nutrition and Food Security",
        "Credits": 3,
        "Course Code": "PSS305",
        "Equivalence Code": "PSS7305"
    },
    {
        "Course Name": "Population Health",
        "Credits": 3,
        "Course Code": "PSS306",
        "Equivalence Code": "PSS7306"
    },
    {
        "Course Name": "Population, Poverty and Development",
        "Credits": 3,
        "Course Code": "PSS401",
        "Equivalence Code": "PSS7401"
    },
    {
        "Course Name": "Family Demography",
        "Credits": 3,
        "Course Code": "PSS402",
        "Equivalence Code": "PSS7402"
    },
    {
        "Course Name": "Population Aging",
        "Credits": 3,
        "Course Code": "PSS403",
        "Equivalence Code": "PSS7403"
    },
    {
        "Course Name": "Population Planning and Human Resource Development",
        "Credits": 3,
        "Course Code": "PSS404",
        "Equivalence Code": "PSS7404"
    },
    {
        "Course Name": "Population Dynamics of Bangladesh",
        "Credits": 3,
        "Course Code": "PSS405",
        "Equivalence Code": "PSS7405"
    },
    {
        "Course Name": "Population Policy and Programs in Bangladesh",
        "Credits": 3,
        "Course Code": "PSS406",
        "Equivalence Code": "PSS7406"
    },
    {
        "Course Name": "Individual Research Project and viva voce",
        "Credits": 4,
        "Course Code": "PPHS495",
        "Equivalence Code": "PPHS7495"
    },
    {
        "Course Name": "Field Trip",
        "Credits": 2,
        "Course Code": "PPHS496",
        "Equivalence Code": "PPHS7496"
    }
]
"""
    data = json.loads(provided_json)
    
    try:
        conn = psycopg2.connect("postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres")
        cur = conn.cursor()
        
        cur.execute("SELECT code, name, credit_val, equivalent_code FROM course_metadata;")
        db_rows = cur.fetchall()
        
        db_metadata = {
            row[0].strip().upper(): {
                "name": str(row[1]).strip() if row[1] else "",
                "credit_val": float(row[2]) if row[2] is not None else 0.0,
                "equivalent_code": str(row[3]).strip().upper() if row[3] else None
            } for row in db_rows
        }
        
        missing = []
        discrepancies = []
        seen_in_json = set()
        
        for item in data:
            code = str(item.get("Course Code")).strip().upper()
            if not code:
                continue
                
            seen_in_json.add(code)
            
            if code not in db_metadata:
                missing.append(item)
            else:
                db_data = db_metadata[code]
                item_name = str(item.get("Course Name")).strip()
                item_credit = float(item.get("Credits", 0.0))
                item_equiv = str(item.get("Equivalence Code")).strip().upper() if item.get("Equivalence Code") else None
                
                diffs = []
                # Soft check for names (ignoring special chars like /)
                if item_name.lower() != db_data["name"].lower() and item_name.lower() not in db_data["name"].lower():
                    diffs.append(f"Name: DB='{db_data['name']}', JSON='{item_name}'")
                
                if item_credit != db_data["credit_val"]:
                    diffs.append(f"Credit: DB={db_data['credit_val']}, JSON={item_credit}")
                    
                if item_equiv and item_equiv != db_data["equivalent_code"]:
                    diffs.append(f"Equiv: DB='{db_data['equivalent_code']}', JSON='{item_equiv}'")
                    
                if diffs:
                    discrepancies.append({
                        "code": code,
                        "diffs": diffs
                    })
        
        print(f"Total courses in JSON: {len(data)}")
        print(f"Total unique codes in JSON: {len(seen_in_json)}")
        print(f"Missing from DB: {len(missing)}")
        print(f"Discrepancies found: {len(discrepancies)}")
        
        if missing:
            print("\n--- Missing Courses ---")
            for m in missing:
                print(f"{m['Course Code']}: {m['Course Name']}")
                
        if discrepancies:
            print("\n--- Discrepancies ---")
            for d in discrepancies:
                print(f"{d['code']}: {', '.join(d['diffs'])}")
                
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    compare_list()
