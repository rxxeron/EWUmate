import urllib.request
url = 'https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/alert-dispatcher'
headers = {
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExMDQxNzQsImV4cCI6MjA4NjY4MDE3NH0.zQc3dq53HBpMeN0rbJA9soF0oYhl7de1_sNnB_9JPoM'
}
try:
    print("Invoking alert-dispatcher...")
    response = urllib.request.urlopen(urllib.request.Request(url, method='POST', headers=headers))
    body = response.read().decode('utf-8')
    print(f"Status: {response.status}")
    print(f"Response: {body}")
except Exception as e:
    import builtins
    if hasattr(e, 'read'): print("Error:", e.read().decode())
    else: print("Exception:", e)
