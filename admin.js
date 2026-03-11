
const SUPABASE_URL = "https://jwygjihrbwxhehijldiz.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExMDQxNzQsImV4cCI6MjA4NjY4MDE3NH0.zQc3dq53HBpMeN0rbJA9soF0oYhl7de1_sNnB_9JPoM";
const BASE_URL = `${SUPABASE_URL}/functions/v1`;

let currentKey = "";
const alertBox = document.getElementById('alertBox');
const loginError = document.getElementById('loginError');

// Initialize Supabase Client
const { createClient } = supabase;
const supabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

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
        
        // Handle Tailwind active classes
        if (tabEl) {
            if (s === tab) {
                tabEl.classList.add('active', 'bg-primary-50', 'text-primary-600', 'font-semibold');
                tabEl.classList.remove('text-gray-600');
            } else {
                tabEl.classList.remove('active', 'bg-primary-50', 'text-primary-600', 'font-semibold');
                tabEl.classList.add('text-gray-600');
            }
        }
    });
    
    document.getElementById('sectionTitle').textContent = tab.charAt(0).toUpperCase() + tab.slice(1).replace('-', ' ');
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
    tableBody.innerHTML = `
        <tr>
            <td colspan="5" class="px-6 py-12 text-center text-gray-400">
                <i class="bi bi-arrow-repeat animate-spin text-2xl block mb-2 text-primary-500"></i>
                Syncing timeline...
            </td>
        </tr>
    `;

    try {
        const { data, error } = await supabaseClient
            .from('semesters')
            .select('*')
            .order('year', { ascending: false })
            .order('season', { ascending: false });

        if (error) throw error;

        if (data.length === 0) {
            tableBody.innerHTML = '<tr><td colspan="5" class="px-6 py-12 text-center text-gray-500 italic">No semesters found in record.</td></tr>';
            return;
        }

        tableBody.innerHTML = data.map(sem => `
            <tr class="hover:bg-gray-50 transition-colors group">
                <td class="px-6 py-4">
                    <div class="font-bold text-gray-900">${sem.name}</div>
                </td>
                <td class="px-6 py-4 font-mono text-xs text-primary-600 font-bold">${sem.code}</td>
                <td class="px-6 py-4 text-sm text-gray-600">${sem.year}</td>
                <td class="px-6 py-4 text-sm text-gray-600">${sem.season}</td>
                <td class="px-6 py-4 text-right">
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${sem.is_historical ? 'bg-gray-100 text-gray-800' : 'bg-green-100 text-green-800'}">
                        ${sem.is_historical ? 'Historical' : 'Live'}
                    </span>
                </td>
            </tr>
        `).join('');
    } catch (e) {
        console.error('Error loading semesters:', e);
        tableBody.innerHTML = `<tr><td colspan="5" class="px-6 py-12 text-center text-red-500 font-medium">Failed to load: ${e.message}</td></tr>`;
    }
}

// Global UI Helpers
function openModal(id) {
    document.getElementById(id).classList.remove('hidden');
}

function closeModal(id) {
    document.getElementById(id).classList.add('hidden');
}

// Add Semester Handler
document.getElementById('addSemesterForm')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector('button[type="submit"]');
    const originalText = btn.innerHTML;
    
    const name = document.getElementById('semName').value;
    const code = document.getElementById('semCode').value;
    const year = parseInt(document.getElementById('semYear').value);
    const season = document.getElementById('semSeason').value;

    btn.disabled = true;
    btn.innerHTML = '<i class="bi bi-arrow-repeat animate-spin"></i> Saving...';

    try {
        const { error } = await supabaseClient
            .from('semesters')
            .insert([{ name, code, year, season, is_historical: true }]); // Default to historical for new manual adds

        if (error) throw error;

        showAlert('success', `${name} has been added to the academic record.`, 'bi-check-circle');
        closeModal('semesterModal');
        e.target.reset();
        loadSemesterRecords();
    } catch (err) {
        showAlert('error', err.message, 'bi-exclamation-triangle');
    } finally {
        btn.disabled = false;
        btn.innerHTML = originalText;
    }
});

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
                    if (!input) return;

                    if (input.type === 'checkbox') {
                        input.checked = cfg[key] === true;
                    } else if (input.type === 'date') {
                        // Format ISO date (YYYY-MM-DD...) to YYYY-MM-DD
                        if (cfg[key]) {
                            input.value = cfg[key].split('T')[0];
                        } else {
                            input.value = "";
                        }
                    } else if (input.type === 'datetime-local') {
                        // Format ISO date to YYYY-MM-DDTHH:MM
                        if (cfg[key]) {
                            const date = new Date(cfg[key]);
                            const offset = date.getTimezoneOffset() * 60000;
                            const localISOTime = (new Date(date - offset)).toISOString().slice(0, 16);
                            input.value = localISOTime;
                        } else {
                            input.value = "";
                        }
                    } else {
                        input.value = cfg[key] || "";
                    }
                });
            }
        });
    } catch (err) {
        console.error("Failed to load configs:", err);
    }
}

async function saveSemesterConfig(cycle) {
    const form = document.getElementById(`configForm-${cycle}`);
    const updateData = {
        semester_type: cycle
    };
    
    // Get all inputs
    const inputs = form.querySelectorAll('input, select');
    inputs.forEach(input => {
        if (!input.name) return;
        
        if (input.type === 'checkbox') {
            updateData[input.name] = input.checked;
        } else if (input.type === 'number') {
            updateData[input.name] = input.value ? parseInt(input.value) : null;
        } else if (input.type === 'datetime-local' && input.value) {
            updateData[input.name] = new Date(input.value).toISOString();
        } else {
            updateData[input.name] = input.value || null;
        }
    });

    const btn = form.querySelector('button');
    const originalText = btn.innerHTML;
    btn.disabled = true;
    btn.innerHTML = '<i class="bi bi-arrow-repeat animate-spin"></i> Syncing...';

    try {
        const res = await fetch(`${SUPABASE_URL}/rest/v1/active_semester?semester_type=eq.${cycle}`, {
            method: 'PATCH',
            headers: {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                'Content-Type': 'application/json',
                'Prefer': 'return=minimal'
            },
            body: JSON.stringify(updateData)
        });

        if (!res.ok) {
             const err = await res.json();
             throw new Error(err.message || "Update failed");
        }

        showAlert("success", `${cycle.toUpperCase()} Cycle Synchronized with Database!`, "bi-check-all");
        await fetchCurrentSemester(); // Refresh badge
    } catch (err) {
        showAlert("danger", "Sync Error: " + err.message, "bi-bug");
    } finally {
        btn.disabled = false;
        btn.innerHTML = originalText;
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
let nextSemester = "";
async function fetchCurrentSemester() {
    try {
        const res = await fetch(`${SUPABASE_URL}/rest/v1/active_semester?select=current_semester,next_semester,semester_type`, {
            headers: {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
            }
        });
        const data = await res.json();
        
        data.forEach(item => {
            const isTri = item.semester_type === 'tri';
            const badgeId = isTri ? 'activeSemesterTri' : 'activeSemesterBi';
            const badge = document.getElementById(badgeId);
            
            if (badge) {
                badge.innerHTML = `<i class="bi bi-${isTri ? '3' : '2'}-square-fill"></i> ${isTri ? 'Tri' : 'Bi'}: ${item.current_semester}`;
            }

            // Store Tri cycle names globally for UI suggestions
            if (isTri) {
                currentSemester = item.current_semester;
                nextSemester = item.next_semester;
            }
        });

        suggestFilename();
    } catch (err) {
        console.error("Error loading active semesters:", err);
        const container = document.getElementById('activeSemestersContainer');
        if (container) container.innerHTML = `<span class="text-red-500 text-[10px] font-bold">Error Syncing Header</span>`;
    }
}

function setSemesterContext(ctx) {
    document.getElementById('semesterContext').value = ctx;
    
    // Update UI buttons
    const curBtn = document.getElementById('ctx-current');
    const upcBtn = document.getElementById('ctx-upcoming');
    
    if (ctx === 'current') {
        curBtn.className = "flex-1 py-1.5 px-3 rounded-lg text-[10px] font-bold transition-all bg-white text-primary-700 shadow-sm border border-gray-200";
        upcBtn.className = "flex-1 py-1.5 px-3 rounded-lg text-[10px] font-bold transition-all text-gray-500 hover:bg-gray-200";
    } else {
        curBtn.className = "flex-1 py-1.5 px-3 rounded-lg text-[10px] font-bold transition-all text-gray-500 hover:bg-gray-200";
        upcBtn.className = "flex-1 py-1.5 px-3 rounded-lg text-[10px] font-bold transition-all bg-white text-primary-700 shadow-sm border border-gray-200";
    }
    
    suggestFilename();
}

function suggestFilename() {
    const folder = document.getElementById('folderSelect').value;
    const ctx = document.getElementById('semesterContext').value;
    const semester = (ctx === 'current') ? (currentSemester || "Spring 2026") : (nextSemester || "Summer 2026");
    
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
