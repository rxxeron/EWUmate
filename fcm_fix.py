import psycopg2
try:
    conn = psycopg2.connect('postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres')
    cur = conn.cursor()
    # Use triple-quoted string for SQL to avoid any quote issues
    sql = """
    DROP POLICY IF EXISTS "Users can update tokens on their device" ON public.fcm_tokens;
    DROP POLICY IF EXISTS "Users can insert their tokens" ON public.fcm_tokens;
    DROP POLICY IF EXISTS "Users can view own tokens" ON public.fcm_tokens;
    DROP POLICY IF EXISTS "Users can delete own tokens" ON public.fcm_tokens;
    
    CREATE POLICY "Allow authenticated token management" 
    ON public.fcm_tokens 
    FOR ALL 
    TO authenticated 
    USING (true) 
    WITH CHECK (auth.uid() = user_id);
    """
    cur.execute(sql)
    conn.commit()
    cur.close()
    conn.close()
    print("FIX_APPLIED_SUCCESSFULLY")
except Exception as e:
    print(f"ERROR: {e}")