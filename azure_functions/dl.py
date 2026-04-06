import urllib.request, json
url = "https://jwygjihrbwxhehijldiz.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc"
req = urllib.request.Request(f"{url}/storage/v1/object/academic_documents/facultylist/Spring%202026.pdf", headers={'apikey': key, 'Authorization': f'Bearer {key}'})
with open('spring2026.pdf', 'wb') as f:
    f.write(urllib.request.urlopen(req).read())
print('Downloaded.')
