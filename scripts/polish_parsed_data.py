import json
import re

def polish_names(data):
    # Words that almost certainly start a description rather than a title
    # These must be followed by more text to trigger truncation, or be very specific
    strict_desc_starts = [
        'this course', 'the objective', 'aims to', 'disseminate', 'upon completion', 
        'conceptual framework', 'regulatory requirements', 'various management', 
        'specifically designed', 'provides an introduction', 'intended for'
    ]
    
    for item in data:
        name = item['name']
        name_lower = name.lower()
        
        # 1. Truncate at strict description signatures
        for frag in strict_desc_starts:
            if frag in name_lower:
                idx = name_lower.find(frag)
                if idx > 0:
                    name = name[:idx]
        
        # 2. Truncate at punctuation followed by lowercase (likely a sentence starting)
        # e.g. "Advanced Accounting. This course..."
        m = re.search(r'\.\s+[a-z]', name)
        if m:
            name = name[:m.start()]

        # 3. Strip trailing junk like "Page X of Y" or table fragments
        name = re.sub(r'Page\s*\d+\s*of\s*\d+', '', name, flags=re.IGNORECASE)
        name = re.sub(r'Theory\s*Laboratory\s*Total', '', name, flags=re.IGNORECASE)
        
        item['name'] = name.strip(': ,-.')
        
    return data

if __name__ == "__main__":
    with open('parsed_courses_final.json', 'r') as f:
        data = json.load(f)
    
    polished_data = polish_names(data)
    
    with open('parsed_courses_final.json', 'w') as f:
        json.dump(polished_data, f, indent=2)
    print("Final Precise Polish complete.")
