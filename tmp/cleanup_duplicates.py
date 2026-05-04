import os
import re
from supabase import create_client, Client

SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co"
SUPABASE_KEY = "REDACTED_SUPABASE_SERVICE_ROLE_KEY"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def normalize_semester(sem):
    if not sem: return sem
    cleaned = re.sub(r'[\s_]', '', sem).lower()
    match = re.match(r'([a-z]+)(\d{4})|(\d{4})([a-z]+)', cleaned)
    if match:
        season = (match.group(1) or match.group(4)).lower()
        year = match.group(2) or match.group(3)
        return f"{season.capitalize()}{year}"
    return sem

def cleanup():
    print("--- Starting Database Cleanup ---")

    # 1. Normalize semester_code in all relevant tables
    tables = ['completed_courses', 'semester_summaries', 'semester_course_marks']
    for table in tables:
        print(f"Processing table: {table}")
        res = supabase.table(table).select("id, semester_code").execute()
        updates = []
        for row in res.data:
            old_val = row['semester_code']
            new_val = normalize_semester(old_val)
            if old_val != new_val:
                supabase.table(table).update({"semester_code": new_val}).eq("id", row['id']).execute()
                print(f"  Updated {old_val} -> {new_val}")

    # 2. Deduplicate completed_courses
    # Rule: One record per (user_id, course_code, semester_code)
    print("Deduplicating completed_courses...")
    res = supabase.table('completed_courses').select("*").execute()
    seen = set()
    to_delete = []
    
    # Sort by created_at desc to keep newest
    data = sorted(res.data, key=lambda x: x.get('created_at', ''), reverse=True)
    
    for row in data:
        key = (row['user_id'], row['course_code'].upper().replace(' ', ''), row['semester_code'])
        if key in seen:
            to_delete.append(row['id'])
        else:
            seen.add(key)
    
    if to_delete:
        print(f"  Deleting {len(to_delete)} duplicate course records...")
        for i in range(0, len(to_delete), 100):
            batch = to_delete[i:i+100]
            supabase.table('completed_courses').delete().in_("id", batch).execute()

    # 3. Deduplicate semester_summaries
    print("Deduplicating semester_summaries...")
    res = supabase.table('semester_summaries').select("*").execute()
    seen_summaries = set()
    to_delete_summaries = []
    
    data = sorted(res.data, key=lambda x: x.get('created_at', ''), reverse=True)
    for row in data:
        key = (row['user_id'], row['semester_code'])
        if key in seen_summaries:
            to_delete_summaries.append(row['id'])
        else:
            seen_summaries.add(key)
            
    if to_delete_summaries:
        print(f"  Deleting {len(to_delete_summaries)} duplicate summary records...")
        for i in range(0, len(to_delete_summaries), 100):
            batch = to_delete_summaries[i:i+100]
            supabase.table('semester_summaries').delete().in_("id", batch).execute()

    print("--- Cleanup Complete ---")

if __name__ == "__main__":
    cleanup()
