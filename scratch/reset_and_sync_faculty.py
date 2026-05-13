import os
import json
import re
import requests
from supabase import create_client
from dotenv import load_dotenv

# Load from root folder to get Service Role Key
load_dotenv(r"d:\EWUmate\EWUmate_Clean\ewumate_v2\.env")

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(url, key)

JSON_FILE = r"d:\EWUmate\EWUmate_Clean\ewumate_v2\scratch\faculty_master_data.json"

def clean_name_simple(n):
    if not n: return ""
    n = re.sub(r'^(Dr|Prof|Engr|Mr|Ms|Mrs)\.?\s+', '', n, flags=re.IGNORECASE)
    return "".join(c for c in n.lower() if c.isalnum())

def reset_and_sync():
    print("STEP 1: Blanking out all designations and photos...")
    try:
        sql_reset = "UPDATE public.faculty_master SET designation_name = NULL, photo_url = NULL, updated_at = NOW() WHERE id IS NOT NULL;"
        supabase.rpc("exec_sql", {"sql_query": sql_reset}).execute()
        print("Reset Successful.")
    except Exception as e:
        print(f"Reset Failed: {e}")
        return

class EWUAutomationEngine:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'X-Requested-With': 'XMLHttpRequest',
            'Accept': 'application/json, text/javascript, */*; q=0.01',
            'Referer': 'https://portal.ewubd.edu/',
            'Origin': 'https://portal.ewubd.edu',
            'Accept-Language': 'en-US,en;q=0.9',
            'Connection': 'keep-alive'
        })
        self.base_url = "https://portal.ewubd.edu"

    def login(self, student_id, password):
        try:
            r = self.session.get(f"{self.base_url}/Account/Login", timeout=15)
            from bs4 import BeautifulSoup
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

def reset_and_sync():
    # ... (step 1 already done, but we'll keep it safe)
    # ...
    print("STEP 2: Syncing from Local JSON...")
    if not os.path.exists(JSON_FILE):
        print(f"Error: {JSON_FILE} not found.")
        return
    with open(JSON_FILE, 'r', encoding='utf-8') as f:
        master_list = json.load(f)
    
    master_map = {clean_name_simple(m['full_name']): m for m in master_list}
    print(f"Loaded {len(master_map)} unique faculty from JSON.")

    print("Logging into Portal...")
    config = supabase.table("scraper_config").select("*").execute().data[0]
    engine = EWUAutomationEngine()
    if not engine.login(config['student_id'], config['password']):
        print("Portal Login Failed.")
        return

    res = engine.session.get(f"{engine.base_url}/api/utility/GetAllFaculty", timeout=30)
    portal_data = res.json()
    print(f"Fetched {len(portal_data)} records from Portal.")

    final_sync_list = []
    for p in portal_data:
        short = (p.get("ShortName") or "").strip().upper()
        
        # Combine name parts
        first = (p.get("FirstName") or "").strip()
        middle = (p.get("MiddleName") or "").strip()
        last = (p.get("LastName") or "").strip()
        p_full = " ".join([f for f in [first, middle, last] if f])
        
        c_name = clean_name_simple(p_full)
        
        if c_name in master_map:
            m_info = master_map[c_name]
            final_sync_list.append({
                "short_name": short,
                "full_name": p_full,
                "designation_name": m_info['designation'],
                "photo_url": m_info['photo_url']
            })

    print(f"Injecting {len(final_sync_list)} premium records...")
    for i in range(0, len(final_sync_list), 100):
        batch = final_sync_list[i:i+100]
        sql_parts = []
        for f in batch:
            full = f['full_name'].replace("'", "''")
            desig = f['designation_name'].replace("'", "''")
            photo = f['photo_url']
            short = f['short_name']
            sql_parts.append(f"UPDATE public.faculty_master SET full_name = '{full}', designation_name = '{desig}', photo_url = '{photo}', updated_at = NOW() WHERE short_name = '{short}';")
        
        if sql_parts:
            supabase.rpc("exec_sql", {"sql_query": "\n".join(sql_parts)}).execute()
            print(f"Injected batch {i//100 + 1}")

    print("\nMission Complete! Your directory is reset and re-fulfilled with premium data.")

if __name__ == "__main__":
    reset_and_sync()
