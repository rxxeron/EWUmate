
import os
import json
import sys

# Ensure optimized_functions is importable
sys.path.append(os.path.join(os.path.dirname(__file__), 'optimized_functions'))

try:
    from parser_exam import parse_exam_pdf
except ImportError:
    from optimized_functions.parser_exam import parse_exam_pdf

def main():
    pdf_path = os.path.join(os.getcwd(), 'Exam Spring 2026.pdf')
    output_path = os.path.join(os.getcwd(), 'exam_schedule.json')
    semester_id = "Spring2026"
    
    if not os.path.exists(pdf_path):
        print(f"Error: {pdf_path} not found.")
        return

    print(f"Parsing {pdf_path} for semester {semester_id}...")
    try:
        exams = parse_exam_pdf(pdf_path, semester_id)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(exams, f, indent=2)
            
        print(f"Success! Parsed {len(exams)} exam entries.")
        print(f"Results saved to {output_path}")
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
