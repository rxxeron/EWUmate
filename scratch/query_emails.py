import psycopg2

DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def fetch_emails():
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    # Let's inspect the count of profiles by app_version first
    print("--- App Version Counts in profiles ---")
    cur.execute("""
        SELECT app_version, COUNT(*) 
        FROM public.profiles 
        GROUP BY app_version 
        ORDER BY COUNT(*) DESC;
    """)
    rows = cur.fetchall()
    for row in rows:
        print(f"Version: {row[0]}, Count: {row[1]}")
        
    print("\n--- Fetching emails of users NOT on v1.0.25 / 1.0.25 / 1.0.26 / v1.0.26 / 1.1.0 / v1.1.0 ---")
    # Query emails of users where app_version is not any of the excluded versions
    cur.execute("""
        SELECT auth.users.email, public.profiles.app_version
        FROM public.profiles
        JOIN auth.users ON public.profiles.id = auth.users.id
        WHERE (public.profiles.app_version IS NULL 
           OR public.profiles.app_version NOT IN ('1.0.25', 'v1.0.25', '1.0.26', 'v1.0.26', '1.1.0', 'v1.1.0'))
          AND auth.users.email IS NOT NULL;
    """)
    user_data = cur.fetchall()
    
    emails = []
    print(f"Total users found: {len(user_data)}")
    for email, version in user_data:
        emails.append(email.strip())
        
    # Remove duplicates and format as comma-separated
    unique_emails = sorted(list(set(emails)))
    comma_separated = ", ".join(unique_emails)
    
    print("\n--- Comma Separated Emails ---")
    print(comma_separated)
    
    # Save to a file in case it's huge
    with open("scratch/filtered_emails.txt", "w") as f:
        f.write(comma_separated)
        
    cur.close()
    conn.close()

if __name__ == "__main__":
    fetch_emails()
