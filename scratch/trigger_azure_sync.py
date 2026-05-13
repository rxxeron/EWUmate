import requests
import subprocess
import json

def get_azure_info():
    print("Fetching Azure trigger info...")
    url = subprocess.check_output('az functionapp function show --name ewumate-parser --function-name portal_sync_trigger --resource-group ewumate-parser-rg --query "invokeUrlTemplate" -o tsv', shell=True).decode().strip()
    key = subprocess.check_output('az functionapp function keys list --name ewumate-parser --function-name portal_sync_trigger --resource-group ewumate-parser-rg --query "default" -o tsv', shell=True).decode().strip()
    return url, key

def trigger_sync():
    try:
        url, key = get_azure_info()
        trigger_url = f"{url}?code={key}&sync_faculty=true"
        print(f"Triggering: {url}?code=***&sync_faculty=true")
        
        # We use a long timeout because faculty sync can take a while
        res = requests.get(trigger_url, timeout=300)
        print(f"Status: {res.status_code}")
        print(f"Response: {res.text}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    trigger_sync()
