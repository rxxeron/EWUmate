
import requests
import json
import time

base_url = "https://us-central1-ewu-stu-togo.cloudfunctions.net"
debug_url = f"{base_url}/fix_metadata_credits" # New Endpoint
admin_key = "EWU_MATE_ADMIN_2026_SECURE"

print(f"Calling {debug_url}...")
try:
    resp = requests.post(debug_url, json={"data": {"secret": admin_key}})
    print("Status:", resp.status_code)
    try:
        print(json.dumps(resp.json(), indent=2))
    except:
        print(resp.text)
except Exception as e:
    print(f"Call failed: {e}")
