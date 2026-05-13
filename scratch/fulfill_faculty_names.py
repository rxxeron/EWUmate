import os
import requests
import re
import json
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from supabase import create_client

# Load root .env for Service Role
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
    return name.title()

def fulfill_names():
    print("Fulfilling Faculty Names from Portal...")
    config = supabase.table("scraper_config").select("*").execute().data[0]
    
    engine = EWUAutomationEngine()
    if engine.login(config['student_id'], config['password']):
        res = engine.session.get(f"{engine.base_url}/api/utility/GetAllFaculty", timeout=30)
        portal_data = res.json()
        print(f"Fetched {len(portal_data)} records from portal.")
        
        faculty_list = []
        for f in portal_data:
            short = (f.get("ShortName") or "").strip().upper()
            if not short: continue
            
            faculty_list.append({
                "short_name": short,
                "full_name": clean_name(f.get("FacultyName")),
                "email": (f.get("Email") or "").strip().lower(),
                "phone": (f.get("Mobile") or "").strip()
            })
        
        print(f"Upserting {len(faculty_list)} records (Protecting Designation & Photo)...")
        # Batch upsert 100 at a time
        for i in range(0, len(faculty_list), 100):
            batch = faculty_list[i:i+100]
            supabase.table("faculty_master").upsert(batch, on_conflict="short_name").execute()
            print(f"Processed batch {i//100 + 1}")
            
        print("Fulfillment Complete!")
    else:
        print("Portal Login Failed.")

if __name__ == "__main__":
    fulfill_names()
