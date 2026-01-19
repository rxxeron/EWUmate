import requests
import json
import sys

# Configuration
PROJECT_ID = "ewu-stu-togo"
REGION = "us-central1"
FUNCTION_URL = f"https://{REGION}-{PROJECT_ID}.cloudfunctions.net/send_broadcast_notification"
SECRET_KEY = "EWU_MATE_BROADCAST_KEY_2026"

def clear_screen():
    print("\033[H\033[J", end="")

def send_request(title, body, link=None):
    print("\nSending Notification...")
    payload = {
        "data": {
            "title": title,
            "body": body,
            "link": link,
            "secret": SECRET_KEY
        }
    }
    
    try:
        response = requests.post(FUNCTION_URL, json=payload, headers={"Content-Type": "application/json"})
        if response.status_code == 200:
            print("✅ Success! Notification sent to all users.")
        else:
            print(f"❌ Failed. Status: {response.status_code}")
            print(response.text)
    except Exception as e:
        print(f"❌ Network Error: {e}")
    
    input("\nPress Enter to continue...")

def manual_broadcast():
    print("\n--- ✍️ Manual Broadcast ---")
    title = input("Title: ").strip()
    if not title: return
    
    body = input("Body: ").strip()
    if not body: return
    
    link = None
    if input("Add a link? (y/n): ").lower().startswith('y'):
        link = input("Link URL: ").strip()
    
    print("\nPreview:")
    print(f"Title: {title}")
    print(f"Body: {body}")
    print(f"Link: {link or 'None'}")
    
    if input("\nSend now? (y/n): ").lower().startswith('y'):
        send_request(title, body, link)
    else:
        print("Cancelled.")

def main():
    while True:
        clear_screen()
        print("📢 EWU Mate Admin Tools")
        print("========================")
        print("1. Send Custom Broadcast")
        print("2. Exit")
        
        choice = input("\nSelect option: ").strip()
        
        if choice == '1':
            manual_broadcast()
        elif choice == '2':
            print("Bye!")
            sys.exit()
        else:
            input("Invalid option.")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nExiting...")
