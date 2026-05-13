from bs4 import BeautifulSoup
import json
import os

HTML_FILE = r"C:\Users\Farzana Safa\Downloads\Faculty Search.html"
OUTPUT_FILE = r"d:\EWUmate\EWUmate_Clean\ewumate_v2\scratch\faculty_master_data.json"
BASE_URL = "https://www.ewubd.edu"

def parse_faculty_html(html_content):
    soup = BeautifulSoup(html_content, 'html.parser')
    faculty_items = soup.select('.department-chairperson-box')
    print(f"Found {len(faculty_items)} faculty boxes in the HTML.")
    
    results = []
    for item in faculty_items:
        # Name and Profile URL
        name_tag = item.select_one('h4.text-center a')
        if not name_tag: continue
        
        name = name_tag.get_text(strip=True)
        profile_url = name_tag['href']
        if not profile_url.startswith('http'):
            profile_url = BASE_URL + (profile_url if profile_url.startswith('/') else '/' + profile_url)
            
        # Designation
        # It's usually the first <p class="text-center">
        p_tags = item.select('p.text-center')
        designation = ""
        if p_tags:
            designation = p_tags[0].get_text(strip=True).replace('\u00a0', ' ')
            
        # Photo
        img_tag = item.select_one('.department-chairperson-box-image img')
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

# I'll expect the HTML to be saved to HTML_FILE first.
# Since I can't read the user's message as a file directly, 
# I'll assume the user wants me to use the HTML content they just pasted.
# I'll create a script that I can run once the file is there.

def main():
    if not os.path.exists(HTML_FILE):
        print(f"Error: {HTML_FILE} not found. Please save the HTML content there.")
        return
        
    with open(HTML_FILE, 'r', encoding='utf-8') as f:
        content = f.read()
        
    faculty_data = parse_faculty_html(content)
    
    if faculty_data:
        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            json.dump(faculty_data, f, indent=4, ensure_ascii=False)
        print(f"Successfully extracted {len(faculty_data)} records to {OUTPUT_FILE}")
    else:
        print("No records extracted. Check HTML structure.")

if __name__ == "__main__":
    main()
