import psycopg2

def trigger_sync():
    try:
        conn = psycopg2.connect('postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres')
        cur = conn.cursor()
        
        # Update the latest log to 'success' to trigger the function
        # Using the ID found earlier: 2d62c2ce-8af6-4de5-96ef-2c39361db835
        cur.execute("UPDATE public.scraper_logs SET status = 'success' WHERE id = '2d62c2ce-8af6-4de5-96ef-2c39361db835'")
        
        conn.commit()
        print("Successfully updated scraper log status to trigger sync.")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    trigger_sync()
