import pg8000.dbapi

def main():
    conn = pg8000.dbapi.connect(
        host="aws-1-ap-south-1.pooler.supabase.com",
        database="postgres",
        user="postgres.jwygjihrbwxhehijldiz",
        password="EWUmaterh12",
        port=5432
    )
    # Autocommit is required for CREATE/DROP statements sometimes, but pg8000 handles it via explicit commit
    conn.autocommit = True
    cursor = conn.cursor()
    
    sql = """
    -- Table to manage your Google Drive accounts
    CREATE TABLE IF NOT EXISTS drive_accounts (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        email TEXT NOT NULL, 
        folder_id TEXT NOT NULL,
        service_account_json JSONB NOT NULL,
        total_capacity_bytes BIGINT DEFAULT 16106127360,
        used_bytes BIGINT DEFAULT 0,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- Table to store the uploaded materials
    CREATE TABLE IF NOT EXISTS study_materials (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        uploader_id UUID REFERENCES auth.users(id),
        faculty_initial TEXT REFERENCES faculty_master(short_name), 
        course_code TEXT REFERENCES course_metadata(code),
        semester TEXT REFERENCES semesters(code),
        file_type TEXT,
        drive_account_id UUID REFERENCES drive_accounts(id), 
        drive_file_id TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_size_bytes BIGINT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- Security
    ALTER TABLE drive_accounts ENABLE ROW LEVEL SECURITY;
    ALTER TABLE study_materials ENABLE ROW LEVEL SECURITY;

    -- Drop existing policies if they exist so we can recreate them
    DROP POLICY IF EXISTS "Anyone can view materials" ON study_materials;
    DROP POLICY IF EXISTS "Users can upload materials" ON study_materials;

    CREATE POLICY "Anyone can view materials" ON study_materials FOR SELECT USING (auth.role() = 'authenticated');
    CREATE POLICY "Users can upload materials" ON study_materials FOR INSERT WITH CHECK (auth.uid() = uploader_id);
    """
    
    try:
        cursor.execute(sql)
        print("SQL executed successfully.")
    except Exception as e:
        print(f"Error executing SQL: {e}")

    cursor.close()
    conn.close()

if __name__ == "__main__":
    main()
