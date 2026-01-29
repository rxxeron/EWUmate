
import os
import sys
from collections import defaultdict

# Add optimized_functions to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'optimized_functions'))

try:
    from parser_course import parse_course_pdf, get_session_duration_minutes
except ImportError:
    from optimized_functions.parser_course import parse_course_pdf, get_session_duration_minutes

def main():
    pdf_path = os.path.join(os.getcwd(), 'Faculty List Spring 2026.pdf')
    if not os.path.exists(pdf_path):
        print(f"Error: PDF not found at {pdf_path}")
        return

    print(f"Parsing {pdf_path} to analyze session types...")
    try:
        # We don't provide course_titles here as we just want to check session logic
        courses = parse_course_pdf(pdf_path, "Spring2026")
        
        duration_distribution = defaultdict(int)
        type_examples = defaultdict(list)
        
        for course in courses:
            for session in course.get('sessions', []):
                start = session.get('startTime')
                end = session.get('endTime')
                sType = session.get('type')
                
                if start and end:
                    duration = get_session_duration_minutes(start, end)
                    key = (duration, sType)
                    duration_distribution[key] += 1
                    
                    if len(type_examples[key]) < 3:
                        type_examples[key].append(f"{course['code']} {session['day']} {start}-{end}")

        print("\n--- Session Duration Analysis ---")
        print(f"{'Duration (min)':<15} {'Type':<10} {'Count':<10} {'Examples'}")
        print("-" * 80)
        
        for (dur, s_type), count in sorted(duration_distribution.items()):
            examples = ", ".join(type_examples[(dur, s_type)])
            print(f"{dur:<15} {s_type:<10} {count:<10} {examples}")

    except Exception as e:
        print(f"Error parsing PDF: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
