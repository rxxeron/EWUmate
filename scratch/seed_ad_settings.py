import requests
import json

URL = "https://jwygjihrbwxhehijldiz.supabase.co/rest/v1/app_config"
KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY"
HEADERS = {"apikey": KEY, "Authorization": f"Bearer {KEY}", "Content-Type": "application/json"}

# First check if exists
res = requests.get(f"{URL}?key=eq.ad_settings", headers=HEADERS)
data = res.json()

if data and len(data) > 0:
    print("ad_settings already exists in DB:", data[0])
else:
    print("ad_settings not found, seeding...")
    payload = {
        "key": "ad_settings",
        "value": {"is_enabled": True}
    }
    res_seed = requests.post(URL, headers=HEADERS, json=payload)
    print("Seed status:", res_seed.status_code)
    print(res_seed.text)
