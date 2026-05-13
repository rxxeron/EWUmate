import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv(r'd:\EWUmate\EWUmate_Clean\ewumate_v2\.env')
sb = create_client(os.environ.get('SUPABASE_URL'), os.environ.get('SUPABASE_SERVICE_ROLE_KEY'))

sql = "SELECT definition FROM pg_views WHERE viewname = 'faculty_directory';"
res = sb.rpc('exec_sql', {'sql_query': sql}).execute()
print(res.data)
