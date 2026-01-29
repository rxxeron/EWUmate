import requests
import json
import time

base_url = "https://us-central1-ewu-stu-togo.cloudfunctions.net"

# 1. Reset Admin Key
bootstrap_url = f"{base_url}/bootstrap_config"
bootstrap_key = "FIRST_TIME_SETUP_2026"
new_admin_key = "EWU_MATE_ADMIN_2026_SECURE"

print(f"Resetting Admin Key via {bootstrap_url}...")
try:
    resp = requests.post(bootstrap_url, json={
        "data": {
            "bootstrap_key": bootstrap_key,
            "admin_key": new_admin_key,
            "semester": "Spring2026"
        }
    })
    print("Bootstrap Status:", resp.status_code)
    print("Bootstrap Response:", resp.text)
except Exception as e:
    print(f"Bootstrap failed: {e}")
    exit(1)

time.sleep(2) # Wait for propagation

# 2. Call Recalculate
recalc_url = f"{base_url}/recalculate_all_stats"
print(f"Calling {recalc_url}...")

try:
    resp = requests.post(recalc_url, json={"data": {"secret": new_admin_key}})
    print("Recalc Status:", resp.status_code)
    print("Recalc Response:", resp.text)
except Exception as e:
    print(f"Recalc failed: {e}")


