import urllib.request
import json
import ssl

def main():
    url = "https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/send-push-notification"
    
    # Securely use the live service role key
    service_role_key = "REDACTED_SUPABASE_SERVICE_ROLE_KEY"
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {service_role_key}"
    }
    
    # User ID from request
    user_id = "bd73b4d7-d922-458f-a52c-40e30e148bf4"
    
    # We construct the record payload as expected by the Edge Function (payload.record)
    payload = {
        "record": {
            "id": "999999", # Custom temporary notification ID
            "user_id": user_id,
            "title": "Hello from EWUMate!",
            "body": "Your push notifications are successfully configured and working!",
            "type": "push_alert"
        }
    }
    
    data = json.dumps(payload).encode("utf-8")
    
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    
    print("--- SENDING POST REQUEST TO SUPABASE EDGE FUNCTION ---")
    print(f"URL: {url}")
    print(f"User ID: {payload['record']['user_id']}")
    print(f"Title: {payload['record']['title']}")
    print(f"Body: {payload['record']['body']}\n")
    
    # Bypass SSL verification if any local environment issues occur
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    
    try:
        with urllib.request.urlopen(req, context=ctx) as response:
            res_body = response.read().decode("utf-8")
            status_code = response.getcode()
            print(f"Response Status Code: {status_code}")
            print("Response Payload:")
            print(json.dumps(json.loads(res_body), indent=2))
    except urllib.error.HTTPError as e:
        print(f"HTTP Error: {e.code} - {e.reason}")
        print("Response Body:")
        print(e.read().decode("utf-8"))
    except Exception as e:
        print(f"Error occurred: {e}")

if __name__ == "__main__":
    main()
