import os
from supabase import create_client
from dotenv import load_dotenv
import json

load_dotenv()

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(url, key)

USER_ID = "160681a3-5c8a-4270-aca7-5bb1ae69ecc1"

def inspect_grid():
    state = supabase.from_('user_semester_states').select('weekly_grid_cache').eq('user_id', USER_ID).eq('semester_code', 'Spring2026').maybe_single().execute()
    if not state.data:
        print("No grid cache found.")
        return
    
    grid = state.data['weekly_grid_cache']
    print("Weekly Grid Cache:")
    print(json.dumps(grid, indent=2))

if __name__ == "__main__":
    inspect_grid()
