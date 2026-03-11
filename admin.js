
const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExMDQxNzQsImV4cCI6MjA4NjY4MDE3NH0.zQc3dq53HBpMeN0rbJA9soF0oYhl7de1_sNnB_9JPoM";
const BASE_URL = `${SUPABASE_URL}/functions/v1`;

let currentKey = "";
const alertBox = document.getElementById('alertBox');
const loginError = document.getElementById('loginError');

async function verifyKey() {
    const inputKey = document.getElementById('loginKey').value.trim();
    const btn = document.getElementById('loginBtn');

    if (!inputKey) {
        showLoginError("Please enter admin password.");
        return;
    }

    setBtnLoading(btn, true, "Verifying...");

    try {
        const res = await fetch(`${BASE_URL}/admin-auth`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                'apikey': SUPABASE_ANON_KEY
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

// Security Management
document.getElementById('adminSecurityForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = document.getElementById('updateAdminPassBtn');
    const originalText = btn.innerHTML;

    const currentPassword = document.getElementById('currentAdminPass').value;
    const newPassword = document.getElementById('newAdminPass').value;

    if (!confirm("Are you sure you want to change the Admin Password? This will update the system security settings.")) return;

    btn.disabled = true;
    btn.innerHTML = '<i class="bi bi-arrow-repeat animate-spin"></i> Updating System Security...';

    try {
        const response = await fetch(`${SUPABASE_URL}/functions/v1/admin-security`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ currentPassword, newPassword })
        });

        const result = await response.json();

        if (result.success) {
            alert("SUCCESS: Admin password has been updated. Please remember your new credentials.");
            e.target.reset();
            // Optional: Logout or redirect
        } else {
            alert("Error: " + (result.error || "Unknown error occurred"));
        }
    } catch (error) {
        alert("Network Error: " + error.message);
    } finally {
        btn.disabled = false;
        btn.innerHTML = originalText;
    }
});

function showLoginError(msg) {
    const loginErrorMessage = document.getElementById('loginErrorMessage');
    loginErrorMessage.textContent = msg;
    loginError.classList.remove('hidden');
}

function transitionSection(fromId, toId) {
    const from = document.getElementById(fromId);
    const to = document.getElementById(toId);
    from.classList.add('hidden');
    to.classList.remove('hidden');
}

function logout() {
    currentKey = "";
    document.getElementById('loginKey').value = '';
    transitionSection('adminSection', 'loginSection');
}

function switchTab(tab) {
    const sections = ['broadcast', 'files', 'holidays', 'direct-message', 'system-fix', 'config', 'security', 'semesters'];
    sections.forEach(s => {
        const el = document.getElementById(`section-${s}`);
        const tabEl = document.getElementById(`tab-${s}`);
        if (el) el.classList.toggle('hidden', s !== tab);
        if (tabEl) tabEl.classList.toggle('active', s === tab);
    });
    alertBox.classList.add('hidden');
    
    if (tab === 'config') {
        loadSemesterConfigs();
    }
    if (tab === 'semesters') {
        loadSemesterRecords();
    }
}

async function loadSemesterRecords() {
    const tableBody = document.getElementById('semester-records-body');
    tableBody.innerHTML = '<tr><td colspan="5" class="text-center">Loading semesters...</td></tr>';

    try {
        const { data, error } = await supabase
            .from('semesters')
            .select('*')
            .order('year', { ascending: false })
            .order('season', { ascending: false });

        if (error) throw error;

        tableBody.innerHTML = data.map(sem => `
            <tr>
                <td class="fw-bold">${sem.name}</td>
                <td><code class="text-cyan">${sem.code}</code></td>
                <td>${sem.year}</td>
                <td>${sem.season}</td>
                <td>
                    <span class="badge ${sem.is_historical ? 'bg-secondary' : 'bg-success'}">
                        ${sem.is_historical ? 'Historical' : 'Active'}
                    </span>
                </td>
            </tr>
        `).join('');
    } catch (e) {
        console.error('Error loading semesters:', e);
        tableBody.innerHTML = `<tr><td colspan="5" class="text-center text-danger">Error: ${e.message}</td></tr>`;
    }
}

async function loadSemesterConfigs() {
    try {
        const res = await fetch(`${SUPABASE_URL}/rest/v1/active_semester?select=*&order=id.asc`, {
            headers: {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
            }
        });
        const data = await res.json();
        
        data.forEach(cfg => {
            const cycle = cfg.semester_type === 'tri' ? 'tri' : 'bi';
            const form = document.getElementById(`configForm-${cycle}`);
            if (form) {
                // Populate all inputs
                Object.keys(cfg).forEach(key => {
                    const input = form.querySelector(`[name="${key}"]`);
                    if (input) input.value = cfg[key] || "";
                });
            }
        });
    } catch (err) {
        console.error("Failed to load configs:", err);
    }
}

async function saveSemesterConfig(cycle) {
    const form = document.getElementById(`configForm-${cycle}`);
    const formData = new FormData(form);
    const id = formData.get('id');
    const updateData = {};
    
    formData.forEach((value, key) => {
        if (key !== 'id') updateData[key] = value || null;
    });

    const btn = form.querySelector('button');
    const originalText = btn.innerText;
    btn.disabled = true;
    btn.innerText = "Applying Changes...";

    try {
        const res = await fetch(`${SUPABASE_URL}/rest/v1/active_semester?id=eq.${id}`, {
            method: 'PATCH',
            headers: {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                'Content-Type': 'application/json',
                'Prefer': 'return=minimal'
            },
            body: JSON.stringify(updateData)
        });

        if (!res.ok) throw new Error("Update failed");

        showAlert("success", `${cycle.toUpperCase()} Cycle Configuration Updated!`, "bi-check-all");
        await fetchCurrentSemester(); // Refresh badge
    } catch (err) {
        showAlert("danger", "Failed to update config: " + err.message, "bi-bug");
    } finally {
        btn.disabled = false;
        btn.innerText = originalText;
    }
}

// BROADCAST LOGIC
document.getElementById('broadcastForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = document.getElementById('sendBtn');
    setBtnLoading(btn, true, "Transmitting...");

    const isScheduled = document.getElementById('scheduleToggle').checked;

    // Fix: Convert local HTML datetime string into absolute UTC ISOString.
    let scheduledAtLocal = null;
    if (isScheduled) {
        const localTimeString = document.getElementById('scheduleTime').value;
        if (localTimeString) {
            // Note: input type="datetime-local" returns something like "2026-03-10T11:00"
            // Passing it straight to `new Date()` parses it in the local timezone of the admin's browser.
            scheduledAtLocal = new Date(localTimeString).toISOString();
        }
    }

    const data = {
        title: document.getElementById('title').value,
        body: document.getElementById('body').value,
        link: document.getElementById('link').value,
        scheduledAt: scheduledAtLocal,
        secret: currentKey
    };

    try {
        const res = await fetch(`${BASE_URL}/broadcast`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                'apikey': SUPABASE_ANON_KEY
            },
            body: JSON.stringify(data)
        });

        const json = await res.json();
        if (!res.ok) throw new Error(json.error || "Broadcast failed");

        showAlert("success", json.message || "Broadcast Sequence Executed Successfully!", "bi-check-circle-fill");
        document.getElementById('broadcastForm').reset();
        document.getElementById('scheduleInputs').classList.add('hidden');
    } catch (err) {
        showAlert("danger", "System Error: " + err.message, "bi-bug-fill");
    } finally {
        setBtnLoading(btn, false, `<i class="bi bi-send-fill"></i> <span class="btn-text">Execute Broadcast</span>`);
    }
});

// UPLOAD LOGIC
document.getElementById('uploadForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = document.getElementById('uploadBtn');
    setBtnLoading(btn, true, "Uploading to Storage...");

    const file = document.getElementById('fileInput').files[0];
    if (!file) return;

    const folder = document.getElementById('folderSelect').value;
    const filename = document.getElementById('filenameInput').value || file.name;
    // URL encode segments to handle spaces/special characters
    const filePath = `${encodeURIComponent(folder)}/${encodeURIComponent(filename)}`;

    try {
        const uploadUrl = `${SUPABASE_URL}/storage/v1/object/academic_documents/${filePath}`;
        const res = await fetch(uploadUrl, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                'apikey': SUPABASE_ANON_KEY,
                'x-upsert': 'true'
            },
            body: file
        });

        if (!res.ok) {
            const err = await res.json();
            throw new Error(err.message || "Storage upload failed");
        }

        showAlert("success", `File uploaded to '${filePath}'. The system will now process it automatically via webhooks.`, "bi-cloud-check-fill");
        document.getElementById('uploadForm').reset();
        suggestFilename();
    } catch (err) {
        showAlert("danger", "Upload failed: " + err.message, "bi-bug-fill");
    } finally {
        setBtnLoading(btn, false, `<i class="bi bi-upload"></i> <span class="btn-text">Ingest Document</span>`);
    }
});

// HOLIDAY LOGIC
document.getElementById('holidayForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = document.getElementById('addHolidayBtn');
    setBtnLoading(btn, true, "Saving Holiday...");

    const data = {
        name: document.getElementById('holidayName').value,
        startDate: document.getElementById('holidayStartDate').value,
        endDate: document.getElementById('holidayEndDate').value,
        secret: currentKey
    };

    try {
        const res = await fetch(`${BASE_URL}/admin-holiday`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                'apikey': SUPABASE_ANON_KEY
            },
            body: JSON.stringify(data)
        });

        const json = await res.json();
        if (!res.ok) throw new Error(json.error || "Failed to add holiday");

        showAlert("success", `Holiday added to ${json.semester} successfully!`, "bi-check-circle-fill");
        document.getElementById('holidayForm').reset();
    } catch (err) {
        showAlert("danger", "System Error: " + err.message, "bi-bug-fill");
    } finally {
        setBtnLoading(btn, false, `<i class="bi bi-calendar-plus-fill"></i> <span class="btn-text">Add Holiday</span>`);
    }
});

// DIRECT MESSAGE LOGIC
document.getElementById('dmForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = document.getElementById('sendDmBtn');
    setBtnLoading(btn, true, "Sending Message...");

    const data = {
        user_id: document.getElementById('dmUserId').value,
        title: document.getElementById('dmTitle').value,
        body: document.getElementById('dmBody').value,
        secret: currentKey
    };

    try {
        const res = await fetch(`${BASE_URL}/admin-direct-message`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                'apikey': SUPABASE_ANON_KEY
            },
            body: JSON.stringify(data)
        });

        const json = await res.json();
        if (!res.ok) throw new Error(json.error || "Failed to send message");

        showAlert("success", "Direct Message sent successfully!", "bi-check-circle-fill");
        document.getElementById('dmForm').reset();
    } catch (err) {
        showAlert("danger", "System Error: " + err.message, "bi-bug-fill");
    } finally {
        setBtnLoading(btn, false, `<i class="bi bi-send-fill"></i> <span class="btn-text">Send Message</span>`);
    }
});

// SYSTEM FIX LOGIC
document.getElementById('singleRepairForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = document.getElementById('repairSingleBtn');
    const userId = document.getElementById('repairUserId').value.trim();
    const action = document.querySelector('input[name="repairType"]:checked').value;

    if (!userId) return;
    setBtnLoading(btn, true, `Syncing ${action}...`);

    try {
        const res = await fetch(`${BASE_URL}/admin-data-repair`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                'apikey': SUPABASE_ANON_KEY
            },
            body: JSON.stringify({
                secret: currentKey,
                type: 'single',
                action: action,
                user_id: userId
            })
        });

        const json = await res.json();
        if (!res.ok) throw new Error(json.error || "Execution failed");

        showAlert("success", `${action.toUpperCase()} sync successful for user!`, "bi-check-circle-fill");
        document.getElementById('singleRepairForm').reset();
    } catch (err) {
        showAlert("danger", "System Error: " + err.message, "bi-bug-fill");
    } finally {
        setBtnLoading(btn, false, `<i class="bi bi-play-fill text-lg"></i> Run Fix`);
    }
});

async function runRepairAction(target) {
    const action = document.querySelector('input[name="repairType"]:checked').value;
    const confirmMsg = target === 'bulk'
        ? `CRITICAL: This will execute ${action.toUpperCase()} sync for ALL users. Proceed?`
        : `Execute ${action} repair?`;

    if (target === 'bulk' && !confirm(confirmMsg)) return;

    const btn = document.getElementById('repairBulkBtn');
    setBtnLoading(btn, true, `Running Global ${action}...`);

    try {
        const res = await fetch(`${BASE_URL}/admin-data-repair`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                'apikey': SUPABASE_ANON_KEY
            },
            body: JSON.stringify({
                secret: currentKey,
                type: target,
                action: action
            })
        });

        const json = await res.json();
        if (!res.ok) throw new Error(json.error || "Repair failed");

        showAlert("success", json.message || "Operation completed successfully!", "bi-shield-check");
    } catch (err) {
        showAlert("danger", "System Error: " + err.message, "bi-bug-fill");
    } finally {
        setBtnLoading(btn, false, `<i class="bi bi-lightning-charge-fill"></i> Execute Global Sync`);
    }
}

async function syncAcademicConfig() {
    if (!confirm("This will scan all active calendars and update the Academic configuration (Dates, Advising, etc.). Proceed?")) return;

    const btn = document.getElementById('syncConfigBtn');
    setBtnLoading(btn, true, "Scanning Calendars...");

    try {
        const res = await fetch(`${BASE_URL}/sync-academic-config`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                'apikey': SUPABASE_ANON_KEY
            },
            body: JSON.stringify({ secret: currentKey })
        });

        const json = await res.json();
        if (!res.ok) throw new Error(json.error || "Sync failed");

        let details = "";
        if (json.results) {
            details = json.results.map(r => 
                `${r.cycle.toUpperCase()}: ${r.status === 'success' ? 'Updated ' + r.fieldsUpdated.join(', ') : (r.error || r.status)}`
            ).join("\n");
        }

        showAlert("success", `Sync operation complete!\n${details}`, "bi-stars");
    } catch (err) {
        showAlert("danger", "System Error: " + err.message, "bi-bug-fill");
    } finally {
        setBtnLoading(btn, false, `<i class="bi bi-cloud-download-fill"></i> Sync Config from Calendars`);
    }
}

let currentSemester = "";
async function fetchCurrentSemester() {
    try {
        const res = await fetch(`${SUPABASE_URL}/rest/v1/active_semester?is_active=eq.true&select=current_semester`, {
            headers: {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
            }
        });
        const json = await res.json();
        if (json && json.length > 0) {
            currentSemester = json[0].current_semester;
            const badge = document.getElementById('activeSemesterBadge');
            if (badge) badge.innerText = `${currentSemester} Active`;
            suggestFilename();
        }
    } catch (err) {
        currentSemester = "";
        const badge = document.getElementById('activeSemesterBadge');
        if (badge) badge.innerText = `Error Loading Semester`;
        suggestFilename();
    }
}

function suggestFilename() {
    const folder = document.getElementById('folderSelect').value;
    const semester = currentSemester || "Spring 2026";
    let filename = "";
    switch (folder) {
        case 'facultylist': filename = `Faculty List ${semester}.pdf`; break;
        case 'academiccalendar': filename = `Academic Calender ${semester}.pdf`; break;
        case 'examschedule': filename = `Exam ${semester}.pdf`; break;
        case 'advisingschedule': filename = `Advising Schedule ${semester}.pdf`; break;
    }
    if (filename) {
        const isDept = document.getElementById('departmentSelect').value === 'phrm_llb';
        if (isDept) {
            filename = filename.replace('.pdf', ' (PHRM_LLB).pdf');
        }
        document.getElementById('filenameInput').value = filename;
    }
}

function setBtnLoading(btn, isLoading, originalHtml) {
    btn.disabled = isLoading;
    btn.innerHTML = isLoading ? `<div class="loader mr-2 border-t-white border-2 w-4 h-4"></div> Processing...` : originalHtml;
}

function showAlert(type, msg, icon) {
    const alertBox = document.getElementById('alertBox');
    const alertIcon = document.getElementById('alertIcon');
    const alertTitle = document.getElementById('alertTitle');
    const alertBody = document.getElementById('alertBody');
    alertBox.className = `fade-in mb-6 p-4 rounded-xl border flex items-center gap-3 shadow-sm ${type === 'success' ? 'bg-green-50 border-green-100 text-green-800' : 'bg-red-50 border-red-100 text-red-800'}`;
    alertIcon.className = `bi ${icon} text-xl ${type === 'success' ? 'text-green-600' : 'text-red-600'}`;
    alertTitle.innerText = type === 'success' ? "Success" : "Error";
    alertBody.innerText = msg;
    alertBox.classList.remove('hidden');
    window.scrollTo({ top: 0, behavior: 'smooth' });
}
