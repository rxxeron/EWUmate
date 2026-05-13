import json
import os
import re
from bs4 import BeautifulSoup

HTML_FILE = r"C:\Users\Farzana Safa\Downloads\Faculty Search.html"
OUTPUT_FILE = r"d:\EWUmate\EWUmate_Clean\ewumate_v2\scratch\faculty_master_data.json"
BASE_URL = "https://www.ewubd.edu"
BASE_STORAGE_URL = "https://www.ewubd.edu/storage/app/uploads/public"

def reconstruct_url(local_url):
    # If it's already a full URL to the storage, keep it
    if "storage/app/uploads/public" in local_url:
        return local_url
        
    # Extract filename from local path
    match = re.search(r'([^/]+\.(jpg|jpeg|png|gif|webp))', local_url)
    if not match: return local_url
    
    filename = match.group(1)
    if len(filename) >= 9:
        f1, f2, f3 = filename[0:3], filename[3:6], filename[6:9]
        return f"{BASE_STORAGE_URL}/{f1}/{f2}/{f3}/{filename}"
    return local_url

def main():
    if not os.path.exists(HTML_FILE):
        print(f"Error: {HTML_FILE} not found.")
        return

    with open(HTML_FILE, 'r', encoding='utf-8') as f:
        soup = BeautifulSoup(f, 'html.parser')

    faculty_list = []
    boxes = soup.select('.department-chairperson-box')
    print(f"Found {len(boxes)} faculty boxes.")

    for box in boxes:
        name_tag = box.find('h4')
        if not name_tag: continue
        
        name = name_tag.get_text(strip=True)
        profile_url = name_tag.find('a')['href'] if name_tag.find('a') else ""
        if profile_url and not profile_url.startswith('http'):
            profile_url = BASE_URL + profile_url
            
        # Designation is usually in the first <p> after h4
        p_tags = box.find_all('p')
        designation = ""
        if p_tags:
            designation = p_tags[0].get_text(strip=True).replace('\u00a0', ' ').replace('&nbsp;', ' ')
            designation = re.sub(r',\s*$', '', designation) # Remove trailing comma
            
        img_tag = box.find('img')
        photo_url = img_tag['src'] if img_tag else ""
        photo_url = reconstruct_url(photo_url)

        faculty_list.append({
            "full_name": name,
            "designation": designation,
            "photo_url": photo_url,
            "profile_url": profile_url
        })

    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(faculty_list, f, indent=4, ensure_ascii=False)

    print(f"Successfully extracted {len(faculty_list)} records to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
