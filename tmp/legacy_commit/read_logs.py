import json, re

with open("scheduler_output.json") as f:
    text = f.read()

resp_line = [l for l in text.split('\n') if l.startswith('Response:')]
if resp_line:
    data = json.loads(resp_line[0].replace('Response: ', ''))
    for log in data.get('logs', []):
        if 'Scheduled logic' in log or 'Error' in log:
            print(log)
    print(data.get('message', ''))