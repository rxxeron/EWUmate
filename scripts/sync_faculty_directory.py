import os
import sys
import re
import time
import logging
from concurrent.futures import ThreadPoolExecutor, as_completed
import requests
from bs4 import BeautifulSoup
import psycopg2

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')

DB_URL = os.environ.get("DATABASE_URL") or 'postgresql://postgres.jwygjihrbwxhehijldiz:EWUmaterh12@aws-1-ap-south-1.pooler.supabase.com:6543/postgres'

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
}

def clean_name(n):
    if not n: return ""
    # remove honorifics for fuzzy matching
    cleaned = re.sub(r'^(Prof(?:essor)?\.?|Dr\.?|Mr\.?|Ms\.?|Mrs\.?)\s+', '', n, flags=re.IGNORECASE).strip()
    return re.sub(r'\s+', ' ', cleaned).lower()

def fetch_faculty_directory():
    url = "https://www.ewubd.edu/search-faculty"
    october_headers = dict(HEADERS)
    october_headers.update({
        'X-Requested-With': 'XMLHttpRequest',
        'X-OCTOBER-REQUEST-HANDLER': 'onFacultySearch',
        'X-OCTOBER-REQUEST-PARTIALS': 'search/facultysearch'
    })
    
    payload = {'department_id': 'all', 'faculty_designation': 'all'}
    logging.info("Fetching central faculty directory from %s...", url)
    res = requests.post(url, headers=october_headers, data=payload, timeout=30)
    res.raise_for_status()
    
    html = res.json().get('search/facultysearch', '')
    soup = BeautifulSoup(html, 'html.parser')
    
    profiles = {}
    for a in soup.find_all('a', href=lambda h: h and '/faculty-profile/' in h):
        href = a.get('href')
        slug = href.split('/faculty-profile/')[-1].strip('/')
        if not slug or slug in profiles:
            continue
            
        card = a.find_parent('div', class_=lambda c: c and ('col' in c or 'card' in c or 'faculty' in c)) or a.parent
        lines = [line.strip() for line in card.get_text(separator='\n', strip=True).split('\n') if line.strip()]
        
        raw_name = lines[0] if len(lines) > 0 else slug
        raw_desig = lines[1] if len(lines) > 1 and "View Profile" not in lines[1] else ""
        
        # Clean designation
        desig_clean = re.sub(r'[\xa0\t\r\n]+', ' ', raw_desig)
        desig_clean = re.sub(r'\s+', ' ', desig_clean).strip(' ,')
        
        # Photo
        img = card.find('img')
        photo_url = img.get('src') if img else ""
        if photo_url and not photo_url.startswith('http'):
            photo_url = f"https://www.ewubd.edu{photo_url}"
            
        profiles[slug] = {
            'slug': slug,
            'raw_name': raw_name,
            'clean_name': clean_name(raw_name),
            'designation': desig_clean,
            'photo_url': photo_url,
            'profile_url': f"https://www.ewubd.edu/faculty-profile/{slug}",
            'email': f"{slug.lower()}@ewubd.edu",  # Default fallback email
            'room': ""
        }
        
    logging.info("Extracted %d faculty profiles from directory listing.", len(profiles))
    return profiles

def fetch_single_profile_details(profile):
    url = profile['profile_url']
    try:
        r = requests.get(url, headers=HEADERS, timeout=12)
        if r.status_code == 200:
            soup = BeautifulSoup(r.text, 'html.parser')
            # Extract mailto
            for a in soup.find_all('a', href=lambda h: h and 'mailto:' in h):
                m = a.get('href').replace('mailto:', '').strip().lower()
                if m and 'ewubd.edu' in m and not any(k in m for k in ['admissions', 'info', 'helpdesk']):
                    profile['email'] = m
                    break
            
            # Extract Room
            text = soup.get_text()
            room_m = re.search(r'Room\s*(?:No#?|#)?\s*([A-Za-z0-9\-/]+)', text, re.IGNORECASE)
            if room_m:
                r_val = room_m.group(1).strip()
                if r_val.lower() != profile['slug'].lower():
                    profile['room'] = r_val
    except Exception as e:
        logging.debug("Detail fetch error for %s: %s", profile['slug'], e)
    return profile

def enrich_faculty_master():
    profiles = fetch_faculty_directory()
    if not profiles:
        logging.error("No profiles fetched.")
        return
        
    logging.info("Harvesting individual profile details (rooms, emails) using 12 threads...")
    enriched_profiles = []
    with ThreadPoolExecutor(max_workers=12) as executor:
        futures = {executor.submit(fetch_single_profile_details, p): p for p in profiles.values()}
        for fut in as_completed(futures):
            enriched_profiles.append(fut.result())
            
    logging.info("Successfully fetched details for %d faculty profiles.", len(enriched_profiles))
    
    conn = psycopg2.connect(DB_URL, connect_timeout=15)
    conn.autocommit = False
    cur = conn.cursor()
    
    try:
        cur.execute("SELECT id, short_name, full_name, email, designation_name, photo_url, office_room FROM faculty_master;")
        db_faculty = cur.fetchall()
        logging.info("Loaded %d faculty records from faculty_master.", len(db_faculty))
        
        db_by_email = {}
        db_by_name = {}
        for r in db_faculty:
            fid, s_name, f_name, email, desig, photo, room = r
            if email and email.strip():
                db_by_email[email.strip().lower()] = r
            cname = clean_name(f_name)
            if cname:
                db_by_name[cname] = r
                
        matched = 0
        updated_photos = 0
        updated_desigs = 0
        updated_rooms = 0
        
        update_rows = []
        for p in enriched_profiles:
            p_email = p['email'].lower()
            p_name = p['clean_name']
            
            target = db_by_email.get(p_email) or db_by_name.get(p_name)
            if target:
                matched += 1
                fid, s_name, db_fname, db_email, curr_desig, curr_photo, curr_room = target
                
                new_photo = p['photo_url'] if p['photo_url'] else curr_photo
                new_desig = p['designation'] if p['designation'] else curr_desig
                new_room = p['room'] if p['room'] else curr_room
                
                if new_photo != curr_photo: updated_photos += 1
                if new_desig != curr_desig: updated_desigs += 1
                if new_room != curr_room and new_room: updated_rooms += 1
                
                update_rows.append((new_desig, new_photo, new_room, fid))
                
        logging.info("Matched %d / %d profiles to DB records.", matched, len(enriched_profiles))
        logging.info("Applying updates to faculty_master: %d photos, %d designations, %d rooms...", updated_photos, updated_desigs, updated_rooms)
        
        if update_rows:
            from psycopg2.extras import execute_batch
            execute_batch(cur, """
                UPDATE faculty_master
                SET designation_name = COALESCE(%s, designation_name),
                    photo_url = COALESCE(%s, photo_url),
                    office_room = COALESCE(%s, office_room),
                    updated_at = NOW()
                WHERE id = %s;
            """, update_rows, page_size=100)
            
        conn.commit()
        logging.info("All faculty updates committed successfully to PostgreSQL!")
        
        cur.execute("""
            SELECT 
                count(*) as total,
                count(case when photo_url is not null and trim(photo_url) != '' then 1 end) as has_photo,
                count(case when designation_name is not null and trim(designation_name) != '' then 1 end) as has_designation,
                count(case when office_room is not null and trim(office_room) != '' then 1 end) as has_room
            FROM faculty_master;
        """)
        stats = cur.fetchone()
        print("\n" + "=" * 50)
        print("UPDATED FACULTY MASTER STATS IN SUPABASE:")
        print("=" * 50)
        print(f"Total Faculty:     {stats[0]}")
        print(f"With Photo URL:    {stats[1]}")
        print(f"With Designation:  {stats[2]}")
        print(f"With Office Room:  {stats[3]}")
        print("=" * 50)
        
    except Exception as e:
        conn.rollback()
        logging.error("Failed during update: %s", e)
        raise
    finally:
        conn.close()

if __name__ == "__main__":
    enrich_faculty_master()
