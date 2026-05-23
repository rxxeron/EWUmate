from google_auth_oauthlib.flow import InstalledAppFlow

# The single Client ID and Secret that represents your EWUMate App
CLIENT_CONFIG = {
    "installed": {
        "client_id": "324713627379-m6s7efnft1tcsvmukrsrp64itn2nn6oq.apps.googleusercontent.com",
        "client_secret": "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",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
    }
}

scopes = ['https://www.googleapis.com/auth/drive']

def main():
    print("==================================================")
    print("      EWUMate OAuth Token Generator")
    print("==================================================")
    print("When your browser opens, make sure to log into one of your 6 Drive accounts.")
    print("If Google says 'Google hasn't verified this app', click 'Advanced' -> 'Go to EWUMate Vault (unsafe)'.")
    print("Make sure to check the box granting access to Google Drive!\n")
    
    flow = InstalledAppFlow.from_client_config(CLIENT_CONFIG, scopes=scopes)
    
    # Run the local server to catch the callback
    creds = flow.run_local_server(port=0)
    
    print("\n✅ SUCCESS! Copy the Refresh Token below:\n")
    print(f"REFRESH_TOKEN: {creds.refresh_token}")
    print("\nNow, put this REFRESH_TOKEN into the 'service_account_json' column for this email in Supabase.")
    print("Run this script again for your next email address!")

if __name__ == '__main__':
    main()
