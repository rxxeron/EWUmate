
import os
import json
import sys

# Add optimized_functions to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'optimized_functions'))

try:
    from parser_exam import parse_exam_pdf
except ImportError:
    # If running from root, might need to adjust import or path
    from optimized_functions.parser_exam import parse_exam_pdf

def main():
    pdf_path = os.path.join(os.getcwd(), 'Exam Spring 2026.pdf')
    output_path = os.path.join(os.getcwd(), 'exam_results.txt')
    
    if not os.path.exists(pdf_path):
        print(f"Error: PDF not found at {pdf_path}")
        return

    print(f"Parsing {pdf_path}...")
    try:
        results = parse_exam_pdf(pdf_path, "Spring2026")
        
        with open(output_path, 'w', encoding='utf-8') as f:
            if not results:
                f.write("No exams found.\n")
                print("No exams found.")
            else:
                for exam in results:
                    f.write(json.dumps(exam, indent=2) + "\n")
                print(f"Found {len(results)} exam entries. Saved to {output_path}")
                
    except Exception as e:
        print(f"Error parsing PDF: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
