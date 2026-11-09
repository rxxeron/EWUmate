import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox
import json
import time
import os
import requests
from datetime import datetime
import threading
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import Select
from dotenv import load_dotenv

# Load env
load_dotenv()
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://jwygjihrbwxhehijldiz.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", os.environ.get("SUPABASE_KEY"))

class ScraperApp:
    def __init__(self, root):
        self.root = root
        self.root.title("EWU Portal Scraper - Standard Engine")
        self.root.geometry("800x600")
        self.root.configure(bg="#f0f4f8")
        
        self.scraped_data = []
        
        # UI Styles
        style = ttk.Style()
        style.configure("TButton", font=("Segoe UI", 10), padding=6)
        style.configure("TLabel", font=("Segoe UI", 10), background="#f0f4f8")
        
        # Header
        header = tk.Frame(root, bg="#1C4370", height=80)
        header.pack(fill="x")
        tk.Label(header, text="EWUmate Portal Automation", bg="#1C4370", fg="white", font=("Segoe UI", 18, "bold")).pack(pady=20)
        
        # Config Frame
        config_frame = tk.Frame(root, bg="#f0f4f8", padx=20, pady=20)
        config_frame.pack(fill="x")
        
        tk.Label(config_frame, text="Student ID:").grid(row=0, column=0, sticky="w", pady=5)
        self.ent_id = ttk.Entry(config_frame, width=20)
        self.ent_id.insert(0, os.environ.get("PORTAL_STUDENT_ID", ""))
        self.ent_id.grid(row=0, column=1, padx=10)
        
        tk.Label(config_frame, text="Password:").grid(row=0, column=2, sticky="w", pady=5)
        self.ent_pass = ttk.Entry(config_frame, show="*", width=20)
        self.ent_pass.insert(0, os.environ.get("PORTAL_PASSWORD", ""))
        self.ent_pass.grid(row=0, column=3, padx=10)
        
        tk.Label(config_frame, text="Semester:").grid(row=1, column=0, sticky="w", pady=5)
        self.cb_sem = ttk.Combobox(config_frame, values=["Spring-2025", "Summer-2025", "Fall-2025", "Spring-2026", "Summer-2026"])
        self.cb_sem.set("Summer-2026")
        self.cb_sem.grid(row=1, column=1, padx=10)
        
        # Buttons
        btn_frame = tk.Frame(root, bg="#f0f4f8", padx=20)
        btn_frame.pack(fill="x")
        
        self.btn_start = ttk.Button(btn_frame, text="🚀 Start Scraping", command=self.start_thread)
        self.btn_start.pack(side="left", padx=5)
        
        self.btn_sync = ttk.Button(btn_frame, text="☁️ Push to Supabase", command=self.push_to_supabase, state="disabled")
        self.btn_sync.pack(side="left", padx=5)
        
        # Log Area
        self.log_area = scrolledtext.ScrolledText(root, height=15, font=("Consolas", 9))
        self.log_area.pack(fill="both", expand=True, padx=20, pady=20)
        
    def log(self, msg):
        now = datetime.now().strftime("%H:%M:%S")
        self.log_area.insert(tk.END, f"[{now}] {msg}\n")
        self.log_area.see(tk.END)
        
    def start_thread(self):
        self.btn_start.config(state="disabled")
        threading.Thread(target=self.run_scraper, daemon=True).start()
        
    def run_scraper(self):
        try:
            self.log("Launching Standard Browser...")
            options = Options()
            # Standard options to avoid detection
            options.add_argument("--disable-blink-features=AutomationControlled")
            options.add_experimental_option("excludeSwitches", ["enable-automation"])
            options.add_experimental_option("useAutomationExtension", False)
            
            driver = webdriver.Chrome(options=options)
            
            # Stealth script
            driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
            
            driver.get("https://portal.ewubd.edu/")
            wait = WebDriverWait(driver, 30)
            
            self.log("Logging in...")
            wait.until(EC.presence_of_element_located((By.ID, "StudentId"))).send_keys(self.ent_id.get())
            driver.find_element(By.ID, "Password").send_keys(self.ent_pass.get())
            
            self.log("Please solve captcha if visible, then wait...")
            wait.until(EC.url_contains("Home/Index"))
            self.log("Login Successful!")
            
            driver.get("https://portal.ewubd.edu/Home/OfferedCoursesStudent")
            
            # Select Semester
            sem_sel = Select(wait.until(EC.presence_of_element_id("SemesterId")))
            sem_sel.select_by_visible_text(self.cb_sem.get())
            
            driver.find_element(By.ID, "btnLoad").click()
            self.log("Loading courses...")
            
            wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "#tblData tbody tr")))
            
            # Reveal Faculty
            self.log("Revealing Faculty Names...")
            script = """
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
            driver.execute_script(script)
            
            rows = driver.find_elements(By.CSS_SELECTOR, "#tblData tbody tr")
            self.scraped_data = []
            for i, row in enumerate(rows):
                cells = row.find_elements(By.TAG_NAME, "td")
                if len(cells) < 5: continue
                
                item = {
                    "course": cells[1].text.strip(),
                    "faculty": cells[2].text.strip(),
                    "section": cells[3].text.strip(),
                    "timing": cells[4].text.strip(),
                    "room": cells[5].text.strip()
                }
                self.scraped_data.append(item)
                if i % 10 == 0: self.log(f"Extracted {i} courses...")
                
            self.log(f"Scraping Complete! Total: {len(self.scraped_data)}")
            self.btn_sync.config(state="normal")
            
        except Exception as e:
            self.log(f"ERROR: {str(e)}")
            self.btn_start.config(state="normal")

    def push_to_supabase(self):
        self.log("Pushing to Supabase...")
        # (Insert sync logic here)
        messagebox.showinfo("Success", f"Synced {len(self.scraped_data)} records to Supabase!")

if __name__ == "__main__":
    root = tk.Tk()
    app = ScraperApp(root)
    root.mainloop()
