import requests
import json
from bs4 import BeautifulSoup

session = requests.Session()
r = session.get("https://portal.ewubd.edu/Account/Login")
soup = BeautifulSoup(r.text, 'html.parser')
f_no = soup.find('input', {'name': 'FirstNo'})['value']
s_no = soup.find('input', {'name': 'SecondNo'})['value']
payload = {'Username': '2025-2-50-009', 'Password': 'rHrakib12@#', 'FirstNo': f_no, 'SecondNo': s_no, 'Answer': str(int(f_no)+int(s_no))}
session.post("https://portal.ewubd.edu/Account/Login", data=payload)

sems = session.get("https://portal.ewubd.edu/api/utility/GetSemesterForDropDown").json()
print(json.dumps(sems, indent=2))
