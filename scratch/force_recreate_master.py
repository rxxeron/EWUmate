import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

sb = create_client(os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY"))

sql = """
DROP TABLE IF EXISTS public.faculty_master CASCADE;

CREATE TABLE public.faculty_master (
  id uuid not null default gen_random_uuid (),
  short_name text not null,
  full_name text not null,
  designation_name text null,
  email text null,
  photo_url text null,
  phone text null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint faculty_master_pkey primary key (id),
  constraint faculty_master_short_name_key unique (short_name)
);
"""

print("Dropping and recreating faculty_master...")
res = sb.rpc("exec_sql", {"sql_query": sql}).execute()
print("Success!")
