import psycopg2

try:
    conn = psycopg2.connect('postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:5432/postgres')
    cur = conn.cursor()
    initials = ('DACY', 'MRDI', 'NHN', 'THD', 'RHM')
    cur.execute("SELECT short_name, full_name FROM faculty_master WHERE short_name IN %s", (initials,))
    rows = cur.fetchall()
    print(f"Matches for {initials}: {rows}")
    cur.close()
    conn.close()
except Exception as e:
    print(f"Error: {e}")
