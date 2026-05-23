import pg8000.dbapi

def main():
    print("Connecting to database...")
    conn = pg8000.dbapi.connect(
        host="aws-1-ap-south-1.pooler.supabase.com",
        database="postgres",
        user="postgres.jwygjihrbwxhehijldiz",
        password="EWUmaterh12",
        port=5432
    )
    cursor = conn.cursor()
    
    print("Granting table permissions...")
    cursor.execute("GRANT SELECT, INSERT, UPDATE, DELETE ON study_materials TO anon;")
    cursor.execute("GRANT SELECT, INSERT, UPDATE, DELETE ON study_materials TO authenticated;")
    
    # Also grant on drive_accounts just in case
    cursor.execute("GRANT SELECT ON drive_accounts TO anon;")
    cursor.execute("GRANT SELECT ON drive_accounts TO authenticated;")
    
    conn.commit()
    cursor.close()
    conn.close()
    print("Permissions granted successfully!")

if __name__ == "__main__":
    main()
