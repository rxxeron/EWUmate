import requests
from bs4 import BeautifulSoup
import json
import time
import os
import re

BASE_URL = "https://www.ewubd.edu"
SEARCH_URL = f"{BASE_URL}/search-faculty"
OUTPUT_FILE = r"d:\EWUmate\EWUmate_Clean\ewumate_v2\scratch\faculty_master_data.json"

def get_session():
    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': '*/*',
        'X-Requested-With': 'XMLHttpRequest',
    })
    return session

def scrape_faculty_list():
    session = get_session()
    print(f"1. Fetching page to extract CSRF token from meta tags...")
    response = session.get(SEARCH_URL)
    if response.status_code != 200:
        print("Failed to access search page.")
        return []

    soup = BeautifulSoup(response.text, 'html.parser')
    
    # CSRF token in October CMS is often in meta[name="csrf-token"]
    csrf_tag = soup.select_one('meta[name="csrf-token"]')
    token = csrf_tag['content'] if csrf_tag else ""
    
    if not token:
        # Fallback to search form tokens if any
        token_tag = soup.select_one('input[name="_token"]')
        token = token_tag['value'] if token_tag else ""

    print(f"2. Sending AJAX request (Handler: onFacultySearch, Partial: search/facultysearch)...")
    
    headers = {
        'X-October-Request-Handler': 'onFacultySearch',
        'X-October-Request-Partials': 'search/facultysearch', # This is the key!
        'X-CSRF-TOKEN': token,
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    }
    
    payload = {
        'department_id': 'all',
        'faculty_designation': 'all',
        '_token': token
    }
    
    search_response = session.post(SEARCH_URL, headers=headers, data=payload)
    
    if search_response.status_code != 200:
        print(f"Search failed: {search_response.status_code}")
        print(f"Response snippet: {search_response.text[:200]}")
        return []

    try:
        data = search_response.json()
        html_content = data.get('search/facultysearch', '')
    except:
        html_content = search_response.text

    soup = BeautifulSoup(html_content, 'html.parser')
    faculty_items = soup.select('.faculty-item')
    print(f"Success! Found {len(faculty_items)} faculty members.")
    
    results = []
    for item in faculty_items:
        name_tag = item.select_one('h4.dean-name a')
        if not name_tag: continue
        
        name = name_tag.get_text(strip=True)
        profile_url = name_tag['href']
        if not profile_url.startswith('http'):
            profile_url = BASE_URL + (profile_url if profile_url.startswith('/') else '/' + profile_url)
        
        designation_tag = item.select_one('p.dean-faculty')
        designation = designation_tag.get_text(strip=True) if designation_tag else ""
        
        img_tag = item.select_one('img')
        photo_url = img_tag['src'] if img_tag else ""
        if photo_url and not photo_url.startswith('http'):
             photo_url = BASE_URL + (photo_url if photo_url.startswith('/') else '/' + photo_url)
        
        results.append({
            'full_name': name,
            'designation': designation,
            'photo_url': photo_url,
            'profile_url': profile_url,
            'department': "" 
        })
        
    return results

def scrape_profile_details(profile_url, session):
    try:
        resp = session.get(profile_url, timeout=10)
        if resp.status_code != 200: return ""
        
        soup = BeautifulSoup(resp.text, 'html.parser')
        dept_tag = soup.select_one('.dean-dept')
        if not dept_tag:
             dept_tag = soup.find(text=re.compile(r'Department of', re.I))
             
        if dept_tag:
            txt = dept_tag.get_text(strip=True) if hasattr(dept_tag, 'get_text') else str(dept_tag)
            return txt.replace('Department of ', '').strip()
    except: pass
    return ""

def main():
    session = get_session()
    all_faculty = scrape_faculty_list()
    if not all_faculty: return

    existing_data = []
    if os.path.exists(OUTPUT_FILE):
        try:
            with open(OUTPUT_FILE, 'r', encoding='utf-8') as f:
                existing_data = json.load(f)
        except: pass
            
    processed_map = {f['profile_url']: f['department'] for f in existing_data if f.get('department')}
    
    print(f"Proceeding to scrape departments for {len(all_faculty)} records...")
    
    final_results = []
    for i, faculty in enumerate(all_faculty):
        url = faculty['profile_url']
        if url in processed_map:
            faculty['department'] = processed_map[url]
        else:
            print(f"[{i+1}/{len(all_faculty)}] {faculty['full_name']}...")
            faculty['department'] = scrape_profile_details(url, session)
            time.sleep(0.3)
            
        final_results.append(faculty)
        if (i + 1) % 10 == 0:
            with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
                json.dump(final_results, f, indent=4, ensure_ascii=False)
    
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(final_results, f, indent=4, ensure_ascii=False)
    print(f"\nDone! Total records harvested: {len(final_results)}")

if __name__ == "__main__":
    main()
