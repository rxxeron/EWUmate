import os
import requests
import json
from bs4 import BeautifulSoup
from dotenv import load_dotenv

load_dotenv()

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

from supabase import create_client
sb = create_client(os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY"))
config = sb.table("scraper_config").select("*").execute().data[0]

engine = EWUAutomationEngine()
if engine.login(config['student_id'], config['password']):
    endpoints = [
        "/api/utility/GetDesignation",
        "/api/utility/GetAllDesignations",
        "/api/utility/GetDesignationForDropDown",
        "/api/utility/GetDesignationList"
    ]
    for ep in endpoints:
        res = engine.session.get(f"{engine.base_url}{ep}", timeout=10)
        print(f"Endpoint {ep}: {res.status_code}")
        if res.status_code == 200:
            print(json.dumps(res.json(), indent=2))
else:
    print("Login Failed.")
