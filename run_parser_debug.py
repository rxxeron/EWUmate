import sys
import json
import os

# Add the current directory to path to allow imports
sys.path.append(os.getcwd())

try:
    from optimized_functions.parser_course import parse_course_pdf
except ImportError:
    # If running from root, might need this
    from optimized_functions.parser_course import parse_course_pdf

pdf_path = r"C:\Users\vboxuser\Documents\New folder\EWUmate\Faculty List Spring 2026.pdf"
semester = "Spring2026"

try:
    print(f"Parsing {pdf_path}...")
    results = parse_course_pdf(pdf_path, semester)
    
    print(f"Found {len(results)} sections.")
    
    # Save to JSON for programatic use
    json_path = "parsed_results.json"
    with open(json_path, 'w') as f:
        json.dump(results, f, indent=2)
    print(f"Full JSON results saved to: {json_path}")

    # Save to TXT for human reading
    txt_path = "parsed_results.txt"
    with open(txt_path, 'w', encoding='utf-8') as f:
        f.write(f"Total Sections Found: {len(results)}\n")
        f.write("="*30 + "\n")
        for i, res in enumerate(results):
            f.write(f"\nSection {i+1}: {res.get('code')} {res.get('section')}\n")
            f.write(f"Capacity: {res.get('capacity')}\n")
            for sess in res.get('sessions', []):
                f.write(f"  {sess.get('day')} {sess.get('startTime')}-{sess.get('endTime')} | Faculty: {sess.get('faculty')} | Room: {sess.get('room')}\n")
    print(f"Full readable list saved to: {txt_path}")

except Exception as e:
    print(f"Error: {e}")
