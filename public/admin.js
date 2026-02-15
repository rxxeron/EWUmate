
const SUPABASE_URL = "https://vcfijikafkofgakxnbib.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZjZmlqaWthZmtvZmdha3huYmliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc1NzY2NjQsImV4cCI6MjA1MzE1MjY2NH0.XcPMCZ69YpXojrfN2M0V0K9w4L5HYdJMpLHU6A3QX0k";

let currentKey = "";
const alertBox = document.getElementById('alertBox');
const loginError = document.getElementById('loginError');

async function verifyKey() {
    const inputKey = document.getElementById('loginKey').value.trim();
    const btn = document.getElementById('loginBtn');
    const loginErrorMessage = document.getElementById('loginErrorMessage');

    if (!inputKey) {
        showLoginError("Please enter admin password.");
        return;
    }

    setBtnLoading(btn, true, "Verifying...");

    try {
        const res = await fetch(`${SUPABASE_URL}/functions/v1/admin-auth`, {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
            },
            body: JSON.stringify({ password: inputKey })
        });

        const json = await res.json();

        if (!res.ok || json.error || !json.success) {
            showLoginError(json.error || "Invalid Admin Password");
            document.getElementById('loginKey').value = '';
        } else {
            currentKey = inputKey;
            await fetchCurrentSemester();
            transitionSection('loginSection', 'adminSection');
            loginError.classList.add('hidden');
        }
    } catch (err) {
        showLoginError("Connection Error: " + err.message);
    } finally {
        setBtnLoading(btn, false, `<span class="btn-text">Authenticate</span> <i class="bi bi-arrow-right"></i>`);
    }
}

function showLoginError(msg) {
    const loginErrorMessage = document.getElementById('loginErrorMessage');
    loginErrorMessage.textContent = msg;
    loginError.classList.remove('hidden');
    // Shake effect
    loginError.style.animation = 'none';
    loginError.offsetHeight; /* trigger reflow */
    loginError.style.animation = 'fadeIn 0.4s ease-out';
}

function transitionSection(fromId, toId) {
    const from = document.getElementById(fromId);
    const to = document.getElementById(toId);

    from.style.opacity = '0';
    from.style.transform = 'translateY(-20px)';

    setTimeout(() => {
        from.classList.add('hidden');
        to.classList.remove('hidden');
        to.style.opacity = '0';
        to.style.transform = 'translateY(20px)';
        to.offsetHeight; /* trigger reflow */
        to.style.transition = 'all 0.5s cubic-bezier(0.4, 0, 0.2, 1)';
        to.style.opacity = '1';
        to.style.transform = 'translateY(0)';
    }, 300);
}

document.getElementById('loginKey').addEventListener('keypress', (e) => {
    if (e.key === 'Enter') verifyKey();
});

function logout() {
    currentKey = "";
    document.getElementById('loginKey').value = '';
    transitionSection('adminSection', 'loginSection');
}

function switchTab(tab) {
    const sections = ['broadcast', 'files', 'migration'];
    sections.forEach(s => {
        const el = document.getElementById(`section-${s}`);
        const tabEl = document.getElementById(`tab-${s}`);
        if (el) el.classList.toggle('hidden', s !== tab);
        if (tabEl) tabEl.classList.toggle('active', s === tab);
    });
    alertBox.classList.add('hidden');
}

document.getElementById('broadcastForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = document.getElementById('sendBtn');
    setBtnLoading(btn, true, "Transmitting...");

    const data = {
        title: document.getElementById('title').value,
        body: document.getElementById('body').value,
        link: document.getElementById('link').value,
        secret: currentKey
    };

    const scheduledTime = document.getElementById('scheduleTime').value;
    if (document.getElementById('scheduleToggle').checked && scheduledTime) {
        data.scheduledAt = new Date(scheduledTime).toISOString();
    }

    try {
        await postData(`${BASE_URL}/send_broadcast_notification`, data);
        showAlert("success", "Broadcast Sequence Executed Successfully!", "bi-check-circle-fill");
        document.getElementById('broadcastForm').reset();
        document.getElementById('scheduleInputs').classList.add('hidden');
    } catch (err) {
        handleAuthError(err);
    } finally {
        setBtnLoading(btn, false, `<i class="bi bi-send-fill"></i> <span class="btn-text">Execute Broadcast</span>`);
    }
});

document.getElementById('uploadForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = document.getElementById('uploadBtn');
    setBtnLoading(btn, true, "Parsing Document...");

    const file = document.getElementById('fileInput').files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = async () => {
        const base64Content = reader.result.split(',')[1];
        const folder = document.getElementById('folderSelect').value;
        const filename = document.getElementById('filenameInput').value || file.name;

        // Map folder to parser type
        const typeMap = {
            'facultylist': 'course',
            'academiccalendar': 'calendar',
            'examschedule': 'exam',
            'advisingschedule': 'advising'
        };

        const data = {
            type: typeMap[folder] || 'course',
            base64Data: base64Content,
            filename: filename,  // Send filename for semester extraction
            saveToDatabase: true,
            debug: false
        };

        try {
            const res = await fetch(`${SUPABASE_URL}/functions/v1/pdf-parser`, {
                method: 'POST',
                headers: { 
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
                },
                body: JSON.stringify(data)
            });

            const result = await res.json();

            if (result.success) {
                showAlert("success", `Successfully parsed ${result.count} items and saved ${result.saved} to database in ${(result.totalTime/1000).toFixed(1)}s!`, "bi-cloud-check-fill");
            } else {
                showAlert("danger", `Parsing failed: ${result.error}`, "bi-exclamation-triangle-fill");
            }
            
            document.getElementById('uploadForm').reset();
            document.getElementById('fileNameDisplay').classList.add('hidden');
            document.getElementById('dropZoneContent').classList.remove('hidden');
            const submitBtn = document.getElementById('uploadBtn');
            submitBtn.classList.add('bg-gray-300', 'cursor-not-allowed');
            submitBtn.classList.remove('bg-primary-600', 'text-white');
            submitBtn.disabled = true;

            suggestFilename(); // Reset to default suggestions
        } catch (err) {
            showAlert("danger", "Upload failed: " + err.message, "bi-bug-fill");
        } finally {
            setBtnLoading(btn, false, `<i class="bi bi-upload"></i> <span class="btn-text">Ingest Document</span>`);
        }
    };
});

let currentSemester = "";

async function fetchCurrentSemester() {
    try {
        const res = await fetch(`${SUPABASE_URL}/rest/v1/config?key=eq.currentSemester&select=value`, {
            headers: {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
            }
        });
        const json = await res.json();
        if (json && json.length > 0 && json[0].value) {
            currentSemester = json[0].value;
            suggestFilename();
        }
    } catch (err) {
        console.error("Failed to fetch current semester:", err);
        currentSemester = "Spring 2026"; // Fallback
        suggestFilename();
    }
}

let manualFilename = false;

function suggestFilename() {
    if (manualFilename) return; // Don't override if user typed something

    const folder = document.getElementById('folderSelect').value;
    const semester = currentSemester || "Spring 2026"; // Fallback if fetch fails
    let filename = "";

    switch (folder) {
        case 'facultylist':
            filename = `Faculty List ${semester}.pdf`;
            break;
        case 'academiccalendar':
            filename = `Academic Calender ${semester}.pdf`;
            break;
        case 'examschedule':
            filename = `Exam ${semester}.pdf`;
            break;
        case 'advisingschedule':
            filename = `Advising Schedule ${semester}.pdf`;
            break;
    }

    if (filename) {
        document.getElementById('filenameInput').value = filename;
    }
}

document.getElementById('filenameInput').addEventListener('input', () => {
    manualFilename = !!document.getElementById('filenameInput').value;
});

document.getElementById('folderSelect').addEventListener('change', () => {
    manualFilename = false; // Reset manual override on type change
    suggestFilename();
});

// Initial suggestion (will be updated after login)
suggestFilename();

// Clear password field to prevent autofill confusion
window.onload = () => {
    const loginKey = document.getElementById('loginKey');
    if(loginKey) loginKey.value = '';
};



async function postData(url, data) {
    const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ data: data })
    });
    const json = await res.json();
    if (!res.ok || json.error) throw new Error(json.error?.message || "Transmission Failure");
    return json.result || json;
}

function setBtnLoading(btn, isLoading, originalHtml) {
    if (!btn) return;
    btn.disabled = isLoading;
    if (isLoading) {
        // Use Tailwind loader
        btn.innerHTML = `<div class="loader mr-2 border-t-white border-2 w-4 h-4"></div> <span>Processing...</span>`;
    } else {
        btn.innerHTML = originalHtml;
    }
}

function showAlert(type, msg, icon) {
    const alertBox = document.getElementById('alertBox');
    const alertIcon = document.getElementById('alertIcon');
    const alertTitle = document.getElementById('alertTitle');
    const alertBody = document.getElementById('alertBody');

    // Reset classes
    alertBox.className = 'fade-in mb-6 p-4 rounded-xl border flex items-center gap-3 shadow-sm';
    
    // Tailwind Colors based on Type
    if (type === 'success') {
        alertBox.classList.add('bg-green-50', 'border-green-100', 'text-green-800');
        alertIcon.classList.add('text-green-600');
        alertTitle.innerText = "Success";
    } else if (type === 'danger') {
         alertBox.classList.add('bg-red-50', 'border-red-100', 'text-red-800');
         alertIcon.classList.add('text-red-600');
         alertTitle.innerText = "Error";
    } else {
        alertBox.classList.add('bg-blue-50', 'border-blue-100', 'text-blue-800');
         alertIcon.classList.add('text-blue-600');
         alertTitle.innerText = "Info";
    }

    alertIcon.className = `bi ${icon} text-xl`;
    alertBody.innerText = msg;

    alertBox.classList.remove('hidden');
    window.scrollTo({ top: 0, behavior: 'smooth' });

    // Auto hide after 8 seconds
    setTimeout(() => {
        alertBox.classList.add('hidden');
    }, 8000);
}

function handleAuthError(err) {
    if (err.message.includes("Invalid") || err.message.includes("UNAUTHENTICATED")) {
        logout();
        showLoginError("Session expired or unauthorized sequence.");
    } else {
        showAlert("danger", "System Error: " + err.message, "bi-bug-fill");
    }
}
async function runGlobalMigration() {
    // SECURITY DOUBLE CHECK
    const confirm1 = confirm("⚠️ DANGER: EXECUTE FULL SYSTEM RESET?\n\nThis will:\n1. Re-sync EVERY user's schedule from scratch.\n2. Recalculate CGPA/Credits for ALL users.\n3. PURGE and RESCHEDULE all notifications.\n\nThis is a heavy operation. Are you sure?");
    if (!confirm1) return;
    
    // Second Confirmation just in case
    if (!confirm("Confirm Execution: Type 'YES' in your mind. This cannot be undone.")) return;

    const btn = document.getElementById('resetBtn');
    setBtnLoading(btn, true, "Executing Master Reset Protocol...");

    try {
        // 1. Python: Sync all user schedules
        showAlert("info", "Phase 1/3: Syncing User Weekly Schedules...", "bi-gear-fill");
        const pyRes = await postData(`${BASE_URL}/system_master_sync`, { secret: currentKey });
        
        // 2. Python: Recalculate Stats
        showAlert("info", `Phase 2/3: Recalculating Statistics (${pyRes.usersSynced} schedules synced)...`, "bi-calculator-fill");
        await postData(`${BASE_URL}/recalculate_all_stats`, { secret: currentKey });

        // 3. Node: Reset and Reschedule Notifications
        showAlert("info", "Phase 3/3: Purging & Rescheduling Notifications...", "bi-bell-fill");
        const nodeRes = await postData(`${BASE_URL}/systemNotificationReset`, { secret: currentKey }); 

        showAlert("success", `System Reset Complete! Notifications purged/rescheduled.`, "bi-check-circle-fill");
    } catch (err) {
        handleAuthError(err);
    } finally {
        setBtnLoading(btn, false, `<i class="bi bi-radioactive"></i> EXECUTE FULL SYSTEM RESET`);
    }
}

async function runMasterSync() {
    if (!confirm("This will overwrite weekly schedules for all users based on their enrolled sections. Continue?")) return;

    const btn = document.getElementById('syncBtn');
    setBtnLoading(btn, true, "Syncing...");

    try {
        const pyRes = await postData(`${BASE_URL}/system_master_sync`, { secret: currentKey });
        showAlert("success", `Sync Complete. ${pyRes.usersSynced} users processed.`, "bi-check-circle-fill");
    } catch (err) {
        handleAuthError(err);
    } finally {
        setBtnLoading(btn, false, `<span class="btn-text">Start Sync</span>`);
    }
}

async function runStatsCalc() {
    if (!confirm("Recalculate CGPA and Credits completed for everyone? This is intensive.")) return;

    const btn = document.getElementById('statsBtn');
    setBtnLoading(btn, true, "Calculating...");

    try {
        const res = await postData(`${BASE_URL}/recalculate_all_stats`, { secret: currentKey });
        showAlert("success", `Stats Updated. Processed ${res.processed} users.`, "bi-calculator-fill");
    } catch (err) {
        handleAuthError(err);
    } finally {
        setBtnLoading(btn, false, `<span class="btn-text">Recalculate Stats</span>`);
    }
}
