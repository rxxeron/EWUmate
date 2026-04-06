import json

def analyze():
    # Load Bulletin Data
    with open('parsed_courses_final.json', 'r') as f:
        bulletin_list = json.load(f)
    bulletin_map = {d['code'].upper().replace('-', '').replace(' ', ''): d for d in bulletin_list}

    # Load DB Data
    with open('merged_courses.json', 'r') as f:
        db_list = json.load(f)
    db_map = {d['course_code'].upper().replace('-', '').replace(' ', ''): d for d in db_list}

    both = set(bulletin_map.keys()) & set(db_map.keys())
    only_bulletin = set(bulletin_map.keys()) - set(db_map.keys())
    only_db = set(db_map.keys()) - set(bulletin_map.keys())

    mismatches = []
    for code in both:
        b_cred = str(bulletin_map[code]['credit']).strip()
        d_cred = str(db_map[code]['credit']).strip()
        if b_cred != d_cred:
            mismatches.append({
                'code': code,
                'bulletin_name': bulletin_map[code]['name'],
                'bulletin_credit': b_cred,
                'db_name': db_map[code]['name'],
                'db_credit': d_cred
            })

    report = {
        'stats': {
            'bulletin_total': len(bulletin_map),
            'db_total': len(db_map),
            'overlap': len(both),
            'only_in_pdf_bulletin': len(only_bulletin),
            'only_in_database': len(only_db),
            'credit_mismatches': len(mismatches)
        },
        'mismatches': mismatches,
        'missing_from_db': sorted(list(only_bulletin))[:50],  # Sample
        'missing_from_bulletin': sorted(list(only_db))[:50]    # Sample
    }

    with open('data_reconciliation_report.json', 'w') as f:
        json.dump(report, f, indent=2)

    print("Analysis Complete!")
    print(f"Overlap: {len(both)}")
    print(f"Differences in Credits: {len(mismatches)}")
    print(f"Courses in Bulletin not in DB: {len(only_bulletin)}")
    print(f"Courses in DB not in Bulletin: {len(only_db)}")

if __name__ == "__main__":
    analyze()
