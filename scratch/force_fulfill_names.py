import os
import requests
import re
import json
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from supabase import create_client

load_dotenv(r"d:\EWUmate\EWUmate_Clean\ewumate_v2\.env")

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(url, key)

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
        except Exception: return False

def clean_name(name):
    if not name: return ""
    name = name.strip()
    name = re.sub(r'^(Mr|Ms|Mrs)\.?\s+', '', name, flags=re.IGNORECASE)
    return name.title().replace("'", "''")

def force_fulfill():
    print("Force Fulfilling Faculty Names via SQL...")
    config = supabase.table("scraper_config").select("*").execute().data[0]
    
    engine = EWUAutomationEngine()
    if engine.login(config['student_id'], config['password']):
        res = engine.session.get(f"{engine.base_url}/api/utility/GetAllFaculty", timeout=30)
        portal_data = res.json()
        print(f"Fetched {len(portal_data)} records.")
        
        # Process in batches of 100 for SQL
        for i in range(0, len(portal_data), 100):
            batch = portal_data[i:i+100]
            values = []
            for f in batch:
                short = (f.get("ShortName") or "").strip().upper().replace("'", "''")
                if not short: continue
                full = clean_name(f.get("FacultyName"))
                email = (f.get("Email") or "").strip().lower().replace("'", "''")
                phone = (f.get("Mobile") or "").strip().replace("'", "''")
                
                values.append(f"('{short}', '{full}', '{email}', '{phone}')")
            
            if values:
                sql = f"""
                INSERT INTO public.faculty_master (short_name, full_name, email, phone)
                VALUES {", ".join(values)}
                ON CONFLICT (short_name) DO UPDATE SET
                    full_name = EXCLUDED.full_name,
                    email = EXCLUDED.email,
                    phone = EXCLUDED.phone,
                    updated_at = NOW();
                """
                try:
                    supabase.rpc("exec_sql", {"sql_query": sql}).execute()
                    print(f"Batch {i//100 + 1} Success")
                except Exception as e:
                    print(f"Batch {i//100 + 1} Error: {e}")
        
        print("Force Fulfillment Complete!")
    else:
        print("Login Failed.")

if __name__ == "__main__":
    force_fulfill()
