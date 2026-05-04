import os
import re

root_dir = r'd:\EWUmate\EWUmate_Clean\ewumate_v2\ewumate_production_build\lib'

# Regex to match print(...) and debugPrint(...) and their trailing semicolons
# This handles optional whitespace and can match across lines if needed, 
# but for most production cleanup, we match the common line-based patterns.
patterns = [
    r'^\s*debugPrint\(.*\);?\s*$',
    r'^\s*print\(.*\);?\s*$',
    r'if\s*\(kDebugMode\)\s*debugPrint\(.*\);?',
    r'if\s*\(kDebugMode\)\s*{\s*debugPrint\(.*\);?\s*}'
]

combined_pattern = re.compile('|'.join(patterns), re.MULTILINE)

def clean_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove the lines matching patterns
    # We replace matching lines with nothing or handle specific cases
    new_content = re.sub(combined_pattern, '', content)
    
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

count = 0
for root, dirs, files in os.walk(root_dir):
    for file in files:
        if file.endswith('.dart'):
            if clean_file(os.path.join(root, file)):
                count += 1

print(f"Cleaned {count} files.")
