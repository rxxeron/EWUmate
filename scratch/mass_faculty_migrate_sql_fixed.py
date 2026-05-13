import os
import requests
import json
import re
from bs4 import BeautifulSoup
from dotenv import load_dotenv

load_dotenv()

# We'll use the scraper's engine logic to get the JSON
class EWUAutomationEngine:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'X-Requested-With': 'XMLHttpRequest',
            'Accept': 'application/json, text/javascript, */*; q=0.01',
            'Referer': 'https://portal.ewubd.edu/'
        })
        self.base_url = "https://portal.ewubd.edu"

    def login(self, student_id, password):
        try:
            r = self.session.get(f"{self.base_url}/Account/Login", timeout=15)
            soup = BeautifulSoup(r.text, 'html.parser')
            f_no_elem = soup.find('input', {'name': 'FirstNo'})
            s_no_elem = soup.find('input', {'name': 'SecondNo'})
            if not f_no_elem or not s_no_elem: return False
            f_no = f_no_elem['value']
            s_no = s_no_elem['value']
            ans = int(f_no) + int(s_no)
            payload = {'Username': student_id, 'Password': password, 'FirstNo': f_no, 'SecondNo': s_no, 'Answer': str(ans)}
            res = self.session.post(f"{self.base_url}/Account/Login", data=payload, allow_redirects=True, timeout=15)
            return "Home/Index" in res.url or "/Home" in res.url
        except Exception:
            return False

def clean_name(name):
    if not name: return ""
    name = name.strip()
    name = re.sub(r'^(Mr|Ms|Mrs)\.?\s+', '', name, flags=re.IGNORECASE)
    return name.title().replace("'", "''")

from supabase import create_client
sb = create_client(os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY"))
config = sb.table("scraper_config").select("*").execute().data[0]

engine = EWUAutomationEngine()
if engine.login(config['student_id'], config['password']):
    res = engine.session.get(f"{engine.base_url}/api/utility/GetAllFaculty", timeout=30)
    portal_data = res.json()
    
    print(f"Applying corrected mass cleanup and phone import to {len(portal_data)} records via direct SQL...")
    
    for i in range(0, len(portal_data), 100):
        batch = portal_data[i:i+100]
        values = []
        for f in batch:
            short = (f.get("FacultyCode") or f.get("ShortName") or "").strip().upper().replace("'", "''")
            if not short: continue
            
            # Reconstruct Full Name from pieces
            fname = f.get("FirstName") or ""
            mname = f.get("MiddleName") or ""
            lname = f.get("LastName") or ""
            raw_full = f" {fname} {mname} {lname} ".strip()
            # If all are null, check if there is a 'FacultyName' fallback
            if not raw_full: raw_full = f.get("FacultyName") or ""
            
            full_name = clean_name(raw_full)
            email = (f.get("Email") or "").strip().lower().replace("'", "''")
            phone = (f.get("Mobile") or "").strip().replace("'", "''")
            photo = (f.get("PhotoLocationUrl") or "").strip().replace("'", "''")
            designation_id = str(f.get("DesignationId") or "")
            
            values.append(f"('{short}', '{full_name}', '{email}', '{phone}', '{photo}', '{designation_id}')")
        
        if values:
            sql = f"""
            INSERT INTO public.faculty_master (short_name, full_name, email, phone, photo_url, designation_name)
            VALUES {", ".join(values)}
            ON CONFLICT (short_name) DO UPDATE SET
                full_name = EXCLUDED.full_name,
                email = EXCLUDED.email,
                phone = EXCLUDED.phone,
                photo_url = EXCLUDED.photo_url,
                designation_name = EXCLUDED.designation_name,
                updated_at = NOW();
            """
            sb.rpc("exec_sql", {"sql_query": sql}).execute()
            print(f"Processed batch {i//100 + 1}")
    
    print("Corrected Mass Cleanup and Phone Import Complete!")
else:
    print("Login Failed.")
