import sys
import json
import os

# Add the current directory to path to allow imports
sys.path.append(os.getcwd())

try:
    from optimized_functions.parser_calendar import parse_calendar_pdf
except ImportError:
    from optimized_functions.parser_calendar import parse_calendar_pdf

pdf_path = r"C:\Users\vboxuser\Documents\New folder\EWUmate\Academic Calender Spring 2026.pdf"
semester = "Spring2026"

try:
    print(f"Parsing Calendar: {pdf_path}...")
    results = parse_calendar_pdf(pdf_path, semester, debug=True)
    
    print(f"Found {len(results)} events.")
    
    # Save to JSON
    json_path = "calendar_results.json"
    with open(json_path, 'w') as f:
        json.dump(results, f, indent=2)
    print(f"Full JSON results saved to: {json_path}")

    # Save to TXT
    txt_path = "calendar_results.txt"
    with open(txt_path, 'w', encoding='utf-8') as f:
        f.write(f"Total Calendar Events Found: {len(results)}\n")
        f.write("="*30 + "\n")
        for i, res in enumerate(results):
            f.write(f"\n[{i+1}] Date: {res.get('date')}\n")
            f.write(f"    Day: {res.get('day')}\n")
            f.write(f"    Event: {res.get('event')}\n")
            f.write(f"    ID: {res.get('docId')}\n")
            
    print(f"Full readable list saved to: {txt_path}")

    # Print first few for immediate verification
    for i, res in enumerate(results[:5]):
        print(f"\nEvent {i+1}: {res.get('date')} ({res.get('day')})")
        print(f"  {res.get('event')}")

except Exception as e:
    print(f"Error: {e}")
