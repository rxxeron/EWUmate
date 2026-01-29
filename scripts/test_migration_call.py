
import requests
import json

base_url = "https://us-central1-ewu-stu-togo.cloudfunctions.net"
func_url = f"{base_url}/system_master_sync"
# Use a key that is likely correct or ask user? I'll assume standard test key or try to read it if local emulator is running. 
# But this is calling REMOTE.
# I'll just use the one from call_debug.py which is likely a valid dev key.
admin_key = "EWU_MATE_ADMIN_2026_SECURE" 

print(f"Calling {func_url}...")
try:
    resp = requests.post(func_url, json={"data": {"secret": admin_key}})
    print(f"Status: {resp.status_code}")
    print("Headers:", resp.headers)
    try:
        print(json.dumps(resp.json(), indent=2))
    except:
        print("Response Text:", resp.text)
except Exception as e:
    print(f"Call failed: {e}")
