import os
import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # 1. withOpacity -> withValues
    # Regex handles simple arguments. Nested parens might fail, but withOpacity usually takes simple doubles.
    content = re.sub(r'\.withOpacity\(([^)]+)\)', r'.withValues(alpha: \1)', content)
    
    # 2. print -> // print
    # Avoid commenting already commented ones
    content = re.sub(r'(\s)(print\s*\()', r'\1// \2', content)

    # 3. dart:ui import in main_shell.dart (specific fix)
    if 'main_shell.dart' in filepath:
        content = content.replace("import 'dart:ui';", "// import 'dart:ui';")

    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {filepath}")

# Walk through lib
root = './lib'
for dirpath, _, filenames in os.walk(root):
    for f in filenames:
        if f.endswith('.dart'):
             fix_file(os.path.join(dirpath, f))
