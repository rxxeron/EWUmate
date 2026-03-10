import sys
import os
import json
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "ewumate_api"))
os.environ["SUPABASE_URL"] = "https://jwygjihrbwxhehijldiz.supabase.co"
os.environ["SUPABASE_SERVICE_KEY"] = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"
from __init__ import _do_parse_calendar, _get_semester_from_path

print("Vars:", _get_semester_from_path("academiccalendar/Academic Calender Spring 2026 (PHRM_LLB).pdf"))

result = _do_parse_calendar("academiccalendar/Academic Calender Spring 2026 (PHRM_LLB).pdf")
print("Result:")
print(json.dumps(result, indent=2))
