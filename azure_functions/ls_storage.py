import urllib.request, json
url = "https://jwygjihrbwxhehijldiz.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"
headers = {"apikey": key, "Authorization": f"Bearer {key}", "Content-Type": "application/json"}
req = urllib.request.Request(f"{url}/storage/v1/object/list/academic_documents", headers=headers, method='POST', data=json.dumps({"prefix": "facultylist"}).encode('utf-8'))
with urllib.request.urlopen(req) as res:
    print(res.read().decode())
