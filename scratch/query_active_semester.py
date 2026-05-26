import requests
import json

URL = "https://jwygjihrbwxhehijldiz.supabase.co/rest/v1/active_semester"
KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY"
HEADERS = {"apikey": KEY, "Authorization": f"Bearer {KEY}", "Content-Type": "application/json"}

res = requests.get(URL, headers=HEADERS)
print("Status Code:", res.status_code)
try:
    print(json.dumps(res.json(), indent=2))
except Exception as e:
    print(res.text)
