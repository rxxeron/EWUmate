import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

sb = create_client(os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY"))

sql = """
-- 1. Enable RLS
ALTER TABLE public.faculty_master ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing wide-open permissions
REVOKE ALL ON public.faculty_master FROM anon, authenticated;

-- 3. Create a secure view that EXCLUDES the phone column
DROP VIEW IF EXISTS public.faculty_directory;
CREATE VIEW public.faculty_directory AS
SELECT id, short_name, full_name, designation_name, email, photo_url, updated_at
FROM public.faculty_master;

-- 4. Grant access to the View for app users
GRANT SELECT ON public.faculty_directory TO authenticated, anon;

-- 5. Ensure the service_role still has full access to the raw table for syncing
GRANT ALL ON public.faculty_master TO service_role;
"""

print("Applying security hardening to faculty data...")
try:
    sb.rpc("exec_sql", {"sql_query": sql}).execute()
    print("Security Patch Applied Successfully!")
    print("Main Table: Locked down with RLS.")
    print("Public Directory: Exposed via secure View (No phone numbers).")
except Exception as e:
    print(f"Error applying security patch: {e}")
