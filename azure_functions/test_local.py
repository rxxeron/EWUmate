"""
Quick local test for EWUmate Azure Functions.
Run: python azure_functions/test_local.py

This tests the core logic WITHOUT Azure Functions runtime.
It directly calls the handler functions against your Supabase DB.
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "ewumate_api"))

# Set env vars for local testing
os.environ["SUPABASE_URL"] = "https://jwygjihrbwxhehijldiz.supabase.co"
os.environ["SUPABASE_SERVICE_KEY"] = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"

from __init__ import handle_recalculate_stats, handle_update_progress, handle_generate_schedules, _get_supabase

def test_credit_lookup():
    """Verify course_metadata credit lookup works."""
    sb = _get_supabase()
    result = sb.table("course_metadata").select("code, credits, credit_val").limit(5).execute()
    print("=== Sample Course Metadata ===")
    for row in result.data:
        print(f"  {row['code']}: credits={row.get('credits')}, credit_val={row.get('credit_val')}")
    print(f"  Total rows fetched (sample): {len(result.data)}")

def test_recalculate_stats(user_id):
    """Test CGPA recalculation for a specific user."""
    print(f"\n=== Testing recalculate_stats for {user_id} ===")
    result = handle_recalculate_stats({"user_id": user_id})
    print(f"  Result: {result}")

def test_generate_schedules(user_id):
    """Test schedule generation."""
    print(f"\n=== Testing generate_schedules ===")
    result = handle_generate_schedules({
        "user_id": user_id,
        "semester": "Spring2026",
        "courses": ["CSE101", "CSE103"],
        "filters": {},
    })
    print(f"  Result: {result}")

if __name__ == "__main__":
    test_credit_lookup()

    # If you have a user_id to test with, uncomment:
    # test_recalculate_stats("YOUR_USER_UUID_HERE")
    # test_generate_schedules("YOUR_USER_UUID_HERE")
    
    print("\n✅ Local tests complete.")
