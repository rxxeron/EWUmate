import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(url, key)

def find_user(name):
    res = supabase.from_('profiles').select('*').ilike('full_name', f'%{name}%').execute()
    if not res.data:
        print(f"No user found with name like {name}")
        return
    
    for user in res.data:
        print(f"User found: {user['full_name']} | ID: {user['id']} | Student ID: {user['student_id']}")
        # Check academic progress / marks
        # Let's try to find tables related to progress
        # Based on previous conversations, there might be a 'completed_courses' or 'student_marks' table
        
if __name__ == "__main__":
    find_user("Afifa")
