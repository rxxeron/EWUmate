import psycopg2
import csv
import os

# Database connection details from .env
DB_URL = "postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres"

def extract_emails():
    try:
        # Connect to the database
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        # Query emails from auth.users
        print("Fetching emails from auth.users...")
        cur.execute("SELECT email FROM auth.users WHERE email IS NOT NULL;")
        emails = cur.fetchall()
        
        # Save to CSV
        output_file = "user_emails.csv"
        with open(output_file, mode='w', newline='', encoding='utf-8') as file:
            writer = csv.writer(file)
            writer.writerow(["Email"]) # Header
            for email in emails:
                writer.writerow([email[0]])
        
        print(f"Successfully extracted {len(emails)} emails to {output_file}")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    extract_emails()
