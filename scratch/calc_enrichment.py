import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

sb = create_client(os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY"))

total = sb.table("courses_summer2025").select("id", count="exact").execute().count
enriched = sb.table("courses_summer2025").select("id", count="exact").neq("faculty_full_name", "").execute().count

print(f"Total courses: {total}")
print(f"Enriched courses: {enriched}")
print(f"Enrichment Rate: {(enriched/total)*100:.2f}%")
