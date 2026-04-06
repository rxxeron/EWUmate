
import os
import json
import urllib.request
import urllib.parse
import urllib.error

SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"
AZURE_URL = "https://ewumate-parser.azurewebsites.net/api/parse_faculty"
AZURE_KEY = "jbhd2pMttP7JxJvUOqCuPiJgsBaU4enpvoUwMkskSHnZAzFuBy2WNg=="

file_path = r"D:\EWUmate\EWUmate_Clean\ewumate_v2\Faculty List Summer 2026.pdf"
storage_path = "facultylist/Faculty List Summer 2026.pdf"

print(f"Reading {file_path}...")
with open(file_path, "rb") as f:
    file_data = f.read()

encoded_path = urllib.parse.quote(storage_path)
upload_url = f"{SUPABASE_URL}/storage/v1/object/academic_documents/{encoded_path}"

req = urllib.request.Request(upload_url, data=file_data, method="POST")
req.add_header("Authorization", f"Bearer {SUPABASE_KEY}")
req.add_header("apikey", SUPABASE_KEY)
req.add_header("Content-Type", "application/pdf")
req.add_header("x-upsert", "true")

print("Uploading to Supabase...")
try:
    with urllib.request.urlopen(req) as response:
        print("Upload status:", response.status)
except urllib.error.HTTPError as e:
    print("Upload failed:", e.code, e.read().decode())

print("Triggering Azure Function...")
payload = json.dumps({"file_path": storage_path}).encode("utf-8")
az_req = urllib.request.Request(AZURE_URL, data=payload, method="POST")
az_req.add_header("Content-Type", "application/json")
az_req.add_header("x-functions-key", AZURE_KEY)

try:
    with urllib.request.urlopen(az_req, timeout=300) as response:
        print("Azure Func status:", response.status)
        print(response.read().decode())
except urllib.error.HTTPError as e:
    print("Azure Func failed:", e.code, e.read().decode())

