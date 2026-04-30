import psycopg2
import os
from dotenv import load_dotenv

def execute_cleanup():
    # Load environment variables from .env
    load_dotenv()
    
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        print("Error: DATABASE_URL not found in .env file.")
        return

    # Remove quotes if present in DATABASE_URL
    if db_url.startswith('"') and db_url.endswith('"'):
        db_url = db_url[1:-1]

    try:
        # Connect to the database
        print("Connecting to database...")
        conn = psycopg2.connect(db_url)
        conn.autocommit = False # We'll handle the transaction ourselves or via the SQL script
        cur = conn.cursor()

        # Read the SQL script
        script_path = os.path.join("scripts", "cleanup_non_target_users.sql")
        print(f"Reading SQL script from {script_path}...")
        with open(script_path, "r") as f:
            sql_script = f.read()

        # Execute the script
        print("Executing cleanup script...")
        cur.execute(sql_script)
        
        # In psycopg2, multiple statements in one execute() call work fine, 
        # but if the script has BEGIN/COMMIT, we should be careful.
        # However, psycopg2 handles it.
        
        conn.commit()
        print("Cleanup completed successfully.")

    except Exception as e:
        print(f"Error during execution: {e}")
        if 'conn' in locals():
            conn.rollback()
    finally:
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    execute_cleanup()
