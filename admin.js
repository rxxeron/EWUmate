
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
    const sections = ['broadcast', 'files', 'holidays', 'direct-message'];
    sections.forEach(s => {
        const el = document.getElementById(`section-${s}`);
        const tabEl = document.getElementById(`tab-${s}`);
        if (el) el.classList.toggle('hidden', s !== tab);
        if (tabEl) tabEl.classList.toggle('active', s === tab);
    });
    alertBox.classList.add('hidden');
}

// BROADCAST LOGIC
document.getElementById('broadcastForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = document.getElementById('sendBtn');
    setBtnLoading(btn, true, "Transmitting...");

    const isScheduled = document.getElementById('scheduleToggle').checked;
    const data = {
        title: document.getElementById('title').value,
        body: document.getElementById('body').value,
        link: document.getElementById('link').value,
        scheduledAt: isScheduled ? document.getElementById('scheduleTime').value : null,
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
    const filePath = `${folder}/${filename}`;

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
            suggestFilename();
        }
    } catch (err) {
        currentSemester = "Spring 2026";
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
    if (filename) document.getElementById('filenameInput').value = filename;
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
