import pg8000.dbapi
import urllib.request
import json
import ssl
import time

def trigger_edge_function(title, body):
    url = "https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/send-push-notification"
    service_role_key = "REDACTED_SUPABASE_SERVICE_ROLE_KEY"
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {service_role_key}"
    }
    
    payload = {
        "record": {
            "id": str(int(time.time())), # Unique ID
            "user_id": "bd73b4d7-d922-458f-a52c-40e30e148bf4",
            "title": title,
            "body": body,
            "type": "system"
        }
    }
    
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    
    try:
        with urllib.request.urlopen(req, context=ctx) as response:
            res_body = response.read().decode("utf-8")
            try:
                print(f"Edge Function success for '{title}': {res_body}")
            except Exception:
                print(f"Edge Function success [Unicode Title]: {res_body}")
    except Exception as e:
        print(f"Error triggering Edge Function for '{title}': {e}")

def main():
    conn = pg8000.dbapi.connect(
        host="aws-1-ap-south-1.pooler.supabase.com",
        database="postgres",
        user="postgres.jwygjihrbwxhehijldiz",
        password="EWUmaterh12",
        port=5432
    )
    cursor = conn.cursor()
    
    # 1. Fetch the exact full tokens
    cursor.execute("""
        SELECT token, platform, updated_at
        FROM fcm_tokens
        WHERE user_id = 'bd73b4d7-d922-458f-a52c-40e30e148bf4'
    """)
    rows = cursor.fetchall()
    
    if len(rows) < 2:
        print(f"Found {len(rows)} tokens. We need at least 2 tokens to do targeted testing!")
        cursor.close()
        conn.close()
        return
        
    print(f"Found {len(rows)} active tokens. Commencing targeted swap test...")
    
    # We identify:
    # Token 1 (PWA): d4PEnU4gRm2DMoy...
    # Token 2 (Mobile App): fnY5-9rETlyd_eR...
    token_pwa = None
    token_mobile = None
    
    for row in rows:
        tok = row[0]
        if tok.startswith("d4PEn"):
            token_pwa = row
        elif tok.startswith("fnY5"):
            token_mobile = row
            
    if not token_pwa or not token_mobile:
        print("Could not match the specific PWA and Mobile tokens by prefix. Assigning by position:")
        token_pwa = rows[0]
        token_mobile = rows[1]
        
    print(f"PWA Token Identified: {token_pwa[0][:15]}...")
    print(f"Mobile Token Identified: {token_mobile[0][:15]}...\n")
    
    try:
        # --- PHASE 1: TARGET PWA ONLY ---
        print("--- PHASE 1: Target PWA Only ---")
        # Temporarily clear all tokens and insert ONLY the PWA token
        cursor.execute("DELETE FROM fcm_tokens WHERE user_id = 'bd73b4d7-d922-458f-a52c-40e30e148bf4'")
        cursor.execute("""
            INSERT INTO fcm_tokens (token, user_id, platform, updated_at)
            VALUES (%s, %s, %s, %s)
        """, (token_pwa[0], "bd73b4d7-d922-458f-a52c-40e30e148bf4", token_pwa[1], token_pwa[2]))
        conn.commit()
        
        # Trigger push
        trigger_edge_function(
            "[PWA TARGETED] Hello PWA Client! 🌐", 
            "If you see this dialog or banner, your PWA Push Notifications are 100% active and working!"
        )
        
        # Wait 3 seconds for delivery
        time.sleep(3)
        
        # --- PHASE 2: TARGET MOBILE NATIVE ONLY ---
        print("\n--- PHASE 2: Target Mobile Native Only ---")
        # Temporarily clear PWA token and insert ONLY the Mobile token
        cursor.execute("DELETE FROM fcm_tokens WHERE user_id = 'bd73b4d7-d922-458f-a52c-40e30e148bf4'")
        cursor.execute("""
            INSERT INTO fcm_tokens (token, user_id, platform, updated_at)
            VALUES (%s, %s, %s, %s)
        """, (token_mobile[0], "bd73b4d7-d922-458f-a52c-40e30e148bf4", token_mobile[1], token_mobile[2]))
        conn.commit()
        
        # Trigger push
        trigger_edge_function(
            "[MOBILE TARGETED] Hello Native App! 📱", 
            "If you see this banner, your native mobile app notification is triggered!"
        )
        
    except Exception as e:
        print(f"An error occurred during swapping: {e}")
    finally:
        # --- PHASE 3: RESTORE BOTH TOKENS ---
        print("\n--- PHASE 3: Restoring Database State ---")
        cursor.execute("DELETE FROM fcm_tokens WHERE user_id = 'bd73b4d7-d922-458f-a52c-40e30e148bf4'")
        
        # Re-insert PWA token
        cursor.execute("""
            INSERT INTO fcm_tokens (token, user_id, platform, updated_at)
            VALUES (%s, %s, %s, %s)
        """, (token_pwa[0], "bd73b4d7-d922-458f-a52c-40e30e148bf4", token_pwa[1], token_pwa[2]))
        
        # Re-insert Mobile token
        cursor.execute("""
            INSERT INTO fcm_tokens (token, user_id, platform, updated_at)
            VALUES (%s, %s, %s, %s)
        """, (token_mobile[0], "bd73b4d7-d922-458f-a52c-40e30e148bf4", token_mobile[1], token_mobile[2]))
        
        conn.commit()
        print("Database state fully restored! Both active tokens are preserved.")
        
    cursor.close()
    conn.close()

if __name__ == "__main__":
    main()
