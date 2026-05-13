import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv(r'd:\EWUmate\EWUmate_Clean\ewumate_v2\.env')
sb = create_client(os.environ.get('SUPABASE_URL'), os.environ.get('SUPABASE_SERVICE_ROLE_KEY'))

print("--- Initializing Active Semester Flags ---")
try:
    # Set Next Semester to True, Advising to False (current defaults)
    res = sb.table('active_semester').update({
        'is_advising_open': False, 
        'is_next_semester_open': True
    }).in_('track', ['tri_semester', 'bi_semester']).execute()
    print("Initialization Successful:", len(res.data), "rows updated.")
except Exception as e:
    print("Failed:", e)
