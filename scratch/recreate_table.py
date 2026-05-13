import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

sb = create_client(os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY"))

sql = """
DROP TABLE IF EXISTS public.courses_summer2026; 
create table public.courses_summer2026 (
  id uuid not null default gen_random_uuid (), 
  course_code text null, 
  original_code text null, 
  section_number text null, 
  faculty_initials text null, 
  capacity text null, 
  schedule_data jsonb null, 
  course_name text null, 
  credit_val numeric null, 
  dedicated_department text null, 
  faculty_designation text null, 
  faculty_full_name text null, 
  constraint courses_summer2026_pkey primary key (id), 
  constraint courses_summer2026_course_code_section_number_key unique (course_code, section_number)
) TABLESPACE pg_default; 
GRANT ALL ON TABLE public.courses_summer2026 TO service_role, postgres; 
GRANT SELECT ON TABLE public.courses_summer2026 TO authenticated;
NOTIFY pgrst, 'reload schema';
"""

print("Dropping and Recreating Summer 2026 Table...")
try:
    sb.rpc("exec_sql", {"sql_query": sql}).execute()
    print("Success!")
except Exception as e:
    print(f"Error: {e}")
