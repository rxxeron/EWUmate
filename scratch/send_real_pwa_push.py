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
            "id": str(int(time.time())),
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
                print(f"Success: {res_body}")
            except Exception:
                print("Success [Unicode response]")
    except Exception as e:
        print(f"Error: {e}")

def main():
    conn = pg8000.dbapi.connect(
        host="aws-1-ap-south-1.pooler.supabase.com",
        database="postgres",
        user="postgres.jwygjihrbwxhehijldiz",
        password="EWUmaterh12",
        port=5432
    )
    cursor = conn.cursor()
    
    # 1. Fetch tokens
    cursor.execute("""
        SELECT token, platform, updated_at
        FROM fcm_tokens
        WHERE user_id = 'bd73b4d7-d922-458f-a52c-40e30e148bf4'
    """)
    rows = cursor.fetchall()
    
    print(f"Found {len(rows)} tokens in database.")
    
    # We want to identify the REAL PWA tokens (which start with 'fIKDEJIFK4zPSsdKQgOEk2')
    # and temporarily delete all OTHER tokens, so we only send to the PWA!
    pwa_tokens = []
    other_tokens = []
    
    for row in rows:
        tok = row[0]
        if tok.startswith("fIKDEJIFK4zPSsd"):
            pwa_tokens.append(row)
        else:
            other_tokens.append(row)
            
    print(f"Identified {len(pwa_tokens)} REAL PWA tokens.")
    print(f"Identified {len(other_tokens)} other tokens.")
    
    if len(pwa_tokens) == 0:
        print("No PWA tokens found! Aborting.")
        cursor.close()
        conn.close()
        return
        
    try:
        # Clear database and insert ONLY the PWA tokens
        print("--- Keeping ONLY PWA tokens in database ---")
        cursor.execute("DELETE FROM fcm_tokens WHERE user_id = 'bd73b4d7-d922-458f-a52c-40e30e148bf4'")
        for pwa_tok in pwa_tokens:
            cursor.execute("""
                INSERT INTO fcm_tokens (token, user_id, platform, updated_at)
                VALUES (%s, %s, %s, %s)
            """, (pwa_tok[0], "bd73b4d7-d922-458f-a52c-40e30e148bf4", pwa_tok[1], pwa_tok[2]))
        conn.commit()
        
        # Trigger targeted push to PWA
        print("Triggering push specifically to PWA...")
        trigger_edge_function(
            "REAL PWA Push Alert! 🌐🎉",
            "This is a dedicated notification sent ONLY to your Progressive Web App. Congratulations!"
        )
        
    except Exception as e:
        print(f"Error during execution: {e}")
    finally:
        # Restore all tokens
        print("--- Restoring all tokens to database ---")
        cursor.execute("DELETE FROM fcm_tokens WHERE user_id = 'bd73b4d7-d922-458f-a52c-40e30e148bf4'")
        for row in rows:
            cursor.execute("""
                INSERT INTO fcm_tokens (token, user_id, platform, updated_at)
                VALUES (%s, %s, %s, %s)
            """, (row[0], "bd73b4d7-d922-458f-a52c-40e30e148bf4", row[1], row[2]))
        conn.commit()
        print("Database state fully restored!")
        
    cursor.close()
    conn.close()

if __name__ == "__main__":
    main()
