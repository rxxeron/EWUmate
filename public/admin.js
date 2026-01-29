
const PROJECT_ID = "ewu-stu-togo";
const REGION = "us-central1";
const BASE_URL = `https://${REGION}-${PROJECT_ID}.cloudfunctions.net`;

let currentKey = "";
const alertBox = document.getElementById('alertBox');
const loginError = document.getElementById('loginError');

async function verifyKey() {
    const inputKey = document.getElementById('loginKey').value.trim();
    const btn = document.getElementById('loginBtn');
    const loginErrorMessage = document.getElementById('loginErrorMessage');

    if (!inputKey) {
        showLoginError("Please enter a sequence key.");
        return;
    }

    setBtnLoading(btn, true, "Verifying...");

    try {
        const res = await fetch(`${BASE_URL}/verify_admin_key`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                data: {
                    secret: inputKey
                }
            })
        });

        const json = await res.json();

        if (json.error) {
            showLoginError(json.error.message || "Invalid Admin Key");
            document.getElementById('loginKey').value = '';
        } else {
            currentKey = inputKey;
            await fetchCurrentSemester();
            transitionSection('loginSection', 'adminSection');
            loginError.classList.add('hidden');
        }
    } catch (err) {
        // If the function doesn't exist yet but returns something (mocking successful bypass for testing if user wants)
        // However, we should be strict.
        showLoginError("System Connection Error: " + err.message);
    } finally {
        setBtnLoading(btn, false, "Unlock Terminal");
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
        setBtnLoading(btn, false, "Execute Broadcast");
    }
});

document.getElementById('uploadForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = document.getElementById('uploadBtn');
    setBtnLoading(btn, true, "Ingesting Document...");

    const file = document.getElementById('fileInput').files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = async () => {
        const base64Content = reader.result.split(',')[1];

        const data = {
            secret: currentKey,
            folder: document.getElementById('folderSelect').value,
            filename: document.getElementById('filenameInput').value,
            file_base64: base64Content
        };

        try {
            const res = await postData(`${BASE_URL}/upload_file_via_admin`, data);
            showAlert("success", `Asset ingested successfully. Processing initiated.`, "bi-cloud-check-fill");
            document.getElementById('uploadForm').reset();
            document.getElementById('fileNameDisplay').classList.add('hidden');
            suggestFilename(); // Reset to default suggestions
        } catch (err) {
            handleAuthError(err);
        } finally {
            setBtnLoading(btn, false, "Ingest Document");
        }
    };
});

let currentSemester = "";

async function fetchCurrentSemester() {
    try {
        const res = await fetch(`${BASE_URL}/get_app_config`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ data: {} })
        });
        const json = await res.json();
        if (json.result && json.result.currentSemester) {
            currentSemester = json.result.currentSemester;
            suggestFilename();
        }
    } catch (err) {
        console.error("Failed to fetch current semester:", err);
    }
}

function suggestFilename() {
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

document.getElementById('folderSelect').addEventListener('change', suggestFilename);

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

function setBtnLoading(btn, isLoading, text) {
    if (!btn) return;
    btn.disabled = isLoading;
    if (isLoading) {
        btn.innerHTML = `<div class="loading-spinner"></div> <span>${text}</span>`;
    } else {
        btn.innerHTML = text.includes('<i') ? text : `<span>${text}</span>`;
    }
}

function showAlert(type, msg, icon) {
    const alertIcon = document.getElementById('alertIcon');
    const alertMessage = document.getElementById('alertMessage');

    alertBox.className = `alert-custom alert-${type}-custom`;
    alertIcon.className = `bi ${icon}`;
    alertMessage.innerText = msg;

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
    if (!confirm("CRITICAL ACTION: This will sync all user data and reset all notifications. Proceed?")) return;

    const btn = document.getElementById('migrationBtn');
    setBtnLoading(btn, true, "Migrating Systems...");

    try {
        // 1. Python: Sync all user schedules
        showAlert("info", "Phase 1/2: Syncing User Weekly Schedules...", "bi-gear-fill");
        const pyRes = await postData(`${BASE_URL}/system_master_sync`, { secret: currentKey });

        // 2. Node: Reset and Reschedule Notifications
        showAlert("info", `Phase 2/2: Rescheduling Notifications (Users Synced: ${pyRes.usersSynced})...`, "bi-bell-fill");
        const nodeRes = await postData(`${BASE_URL}/systemNotificationReset`, { secret: currentKey });

        showAlert("success", `Migration Complete! ${pyRes.usersSynced} schedules and ${nodeRes.message} tasks updated.`, "bi-rocket-takeoff-fill");
    } catch (err) {
        handleAuthError(err);
    } finally {
        setBtnLoading(btn, false, "Trigger Global System Sync");
    }
}
