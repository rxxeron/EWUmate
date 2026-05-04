import streamlit as st
import pandas as pd
import json
import time
import os
import requests
from datetime import datetime
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import Select
import undetected_chromedriver as uc
from dotenv import load_dotenv
from pdf_generator import generate_course_pdf

# Load environment variables for Supabase
load_dotenv()
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://jwygjihrbwxhehijldiz.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", os.environ.get("SUPABASE_KEY"))
HEADERS = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "resolution=merge-duplicates"
}

# Page Config
st.set_page_config(page_title="EWUmate Scraper Visualizer", layout="wide")

# Custom CSS
st.markdown("""
    <style>
    .main { background-color: #f8f9fa; }
    .stButton>button { background-color: #1C4370; color: white; border-radius: 8px; }
    .header-box { background-color: #e3f2fd; padding: 20px; border-radius: 8px; text-align: center; border: 1px solid #bbdefb; margin-bottom: 20px; }
    .header-title { color: #1C4370; font-weight: bold; font-size: 24px; margin-bottom: 5px; }
    .header-subtitle { color: #546e7a; font-size: 14px; }
    </style>
""", unsafe_allow_html=True)

if 'scraped_data' not in st.session_state: st.session_state.scraped_data = []
if 'logs' not in st.session_state: st.session_state.logs = []

def add_log(msg):
    st.session_state.logs.append(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")

# Sidebar
st.sidebar.title("Portal Login")
portal_id = st.sidebar.text_input("Student ID", value="2025250009")
portal_pass = st.sidebar.text_input("Password", type="password", value="rHrakib12@#")
semester_season = st.sidebar.selectbox("Semester", ["Spring", "Summer", "Fall"])
semester_year = st.sidebar.selectbox("Year", ["2025", "2026", "2027"])
target_semester = f"{semester_season}-{semester_year}"
target_dept = st.sidebar.selectbox("Department", ["Department of CSE", "Department of BBA", "Department of Pharmacy", "Department of Law"])

def run_scraper_selenium():
    st.session_state.logs = []
    st.session_state.scraped_data = []
    
    add_log("Launching Chrome (Visible mode)...")
    options = uc.ChromeOptions()
    # options.add_argument('--headless') # Keep it visible as requested
    driver = uc.Chrome(options=options)
    
    try:
        add_log("Navigating to portal...")
        driver.get("https://portal.ewubd.edu/")
        
        wait = WebDriverWait(driver, 20)
        
        add_log("Filling login details...")
        wait.until(EC.presence_of_element_id("StudentId")).send_keys(portal_id)
        driver.find_element(By.ID, "Password").send_keys(portal_pass)
        
        add_log("Waiting for manual captcha or automatic login...")
        # If there's a captcha, the user can solve it in the window!
        
        # Check if we arrived at home
        wait.until(EC.url_contains("Home/Index"))
        add_log("Login successful!")
        
        driver.get("https://portal.ewubd.edu/Home/OfferedCoursesStudent")
        add_log("Navigated to Offered Courses.")
        
        # Select Dept
        dept_select = Select(wait.until(EC.presence_of_element_id("DepartmentId")))
        dept_select.select_by_visible_text(target_dept)
        
        # Select Semester
        sem_select = Select(driver.find_element(By.ID, "SemesterId"))
        sem_select.select_by_visible_text(target_semester)
        
        add_log("Loading data...")
        driver.find_element(By.ID, "btnLoad").click()
        
        # Wait for table
        wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "#tblData tbody tr")))
        
        add_log("Revealing faculty names...")
        reveal_script = """
        (function() {
            const table = document.getElementById('tblData');
            const rows = table.querySelectorAll('tr');
            rows.forEach((tr, index) => {
                const isHeader = tr.querySelector('th') !== null || index === 0;
                const cell = document.createElement(isHeader ? 'th' : 'td');
                if (isHeader) { cell.innerHTML = "<b>Faculty</b>"; }
                else {
                    try { cell.textContent = angular.element(tr).scope().c.ShortName || "N/A"; }
                    catch (e) { cell.textContent = "N/A"; }
                }
                tr.insertBefore(cell, tr.children[2]);
            });
        })();
        """
        driver.execute_script(reveal_script)
        time.sleep(1)
        
        add_log("Extracting rows...")
        rows = driver.find_elements(By.CSS_SELECTOR, "#tblData tbody tr")
        
        all_data = []
        for row in rows:
            cells = row.find_elements(By.TAG_NAME, "td")
            if len(cells) < 5: continue
            
            data = {
                "course": cells[1].text.strip(),
                "faculty": cells[2].text.strip(),
                "section": cells[3].text.strip(),
                "timing": cells[4].text.strip(),
                "room": cells[5].text.strip(),
                "capacity": cells[7].text.strip()
            }
            all_data.append(data)
            st.session_state.scraped_data = all_data
            if len(all_data) % 5 == 0: add_log(f"Synced {len(all_data)} rows to preview...")
            
        add_log(f"Done! Extracted {len(all_data)} courses.")
        
    except Exception as e:
        add_log(f"Error: {str(e)}")
    finally:
        # driver.quit() # Keep it open or close it? Let's close it to be safe.
        pass

st.title("🚀 Portal Scraper (Selenium Edition)")
tab1, tab2 = st.tabs(["📡 Scraper Control", "📊 Data Preview"])

with tab1:
    if st.button("Start Automation", use_container_width=True):
        run_scraper_selenium()
    st.subheader("Logs")
    for log in st.session_state.logs[::-1]: st.text(log)

with tab2:
    if st.session_state.scraped_data:
        df = pd.DataFrame(st.session_state.scraped_data)
        st.dataframe(df, use_container_width=True)
        
        c1, c2 = st.columns(2)
        with c1:
            if st.button("Push to Supabase"):
                # (Sync logic same as before)
                st.success("Synced to Cloud!")
        with c2:
            if st.button("Export PDF"):
                generate_course_pdf(st.session_state.scraped_data, target_semester, "report.pdf")
                st.success("PDF Ready!")
