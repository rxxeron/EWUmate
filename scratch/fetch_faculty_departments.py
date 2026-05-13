import requests
from bs4 import BeautifulSoup
import json
import time
import os
import re
from concurrent.futures import ThreadPoolExecutor

INPUT_FILE = r"d:\EWUmate\EWUmate_Clean\ewumate_v2\scratch\faculty_master_data.json"
OUTPUT_FILE = r"d:\EWUmate\EWUmate_Clean\ewumate_v2\scratch\faculty_master_data_complete.json"

def get_session():
    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    })
    return session

def scrape_department(faculty, session):
    url = faculty['profile_url']
    if faculty.get('department'):
        return faculty['department']
        
    try:
        resp = session.get(url, timeout=10)
        if resp.status_code != 200: return ""
        
        soup = BeautifulSoup(resp.text, 'html.parser')
        # Main selector
        dept_tag = soup.select_one('.dean-dept')
        if not dept_tag:
            # Fallback for some pages
            dept_tag = soup.find(text=re.compile(r'Department of', re.I))
            
        if dept_tag:
            txt = dept_tag.get_text(strip=True) if hasattr(dept_tag, 'get_text') else str(dept_tag)
            return txt.replace('Department of ', '').strip()
    except Exception as e:
        print(f"Error scraping {url}: {e}")
    return ""

def main():
    if not os.path.exists(INPUT_FILE):
        print(f"Error: {INPUT_FILE} not found.")
        return
        
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        faculty_list = json.load(f)
        
    session = get_session()
    total = len(faculty_list)
    print(f"Starting deep-dive for {total} faculty members...")
    
    # We'll use a loop to be safe and polite to the server
    for i, faculty in enumerate(faculty_list):
        if faculty.get('department'):
            continue
            
        print(f"[{i+1}/{total}] Fetching Department for: {faculty['full_name']}...")
        dept = scrape_department(faculty, session)
        faculty['department'] = dept
        
        # Save every 10 to prevent data loss
        if (i + 1) % 10 == 0:
            with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
                json.dump(faculty_list, f, indent=4, ensure_ascii=False)
        
        time.sleep(0.3) # Politeness delay
        
    # Final save
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(faculty_list, f, indent=4, ensure_ascii=False)
        
    print(f"\nSUCCESS! Complete master data saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
