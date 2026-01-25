
const PROJECT_ID = "ewu-stu-togo";
const REGION = "us-central1";
const BASE_URL = `https://${REGION}-${PROJECT_ID}.cloudfunctions.net`;

let currentKey = "";
const alertBox = document.getElementById('alertBox');

async function verifyKey() {
    const inputKey = document.getElementById('loginKey').value.trim();
    const errorDiv = document.getElementById('loginError');
    const btn = document.getElementById('loginBtn');

    if (!inputKey) {
        errorDiv.textContent = "❌ Please enter a key";
        errorDiv.classList.remove('d-none');
        return;
    }

    btn.disabled = true;
    btn.innerText = "Verifying...";

    try {
        const res = await fetch(`${BASE_URL}/send_broadcast_notification`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                data: {
                    secret: inputKey,
                    title: "__verify__",
                    body: "__verify__"
                }
            })
        });

        const json = await res.json();

        if (json.error && json.error.message &&
            (json.error.message.includes("Invalid") || json.error.message.includes("UNAUTHENTICATED"))) {
            errorDiv.textContent = "❌ Invalid Admin Key";
            errorDiv.classList.remove('d-none');
            document.getElementById('loginKey').value = '';
        } else {
            currentKey = inputKey;
            document.getElementById('loginSection').classList.add('d-none');
            document.getElementById('adminSection').classList.remove('d-none');
            errorDiv.classList.add('d-none');
        }
    } catch (err) {
        currentKey = inputKey;
        document.getElementById('loginSection').classList.add('d-none');
        document.getElementById('adminSection').classList.remove('d-none');
        errorDiv.classList.add('d-none');
    } finally {
        btn.disabled = false;
        btn.innerText = "🔓 Unlock Admin Panel";
    }
}

document.getElementById('loginKey').addEventListener('keypress', (e) => {
    if (e.key === 'Enter') verifyKey();
});

function logout() {
    currentKey = "";
    document.getElementById('adminSection').classList.add('d-none');
    document.getElementById('loginSection').classList.remove('d-none');
    document.getElementById('loginKey').value = '';
}

function switchTab(tab) {
    document.getElementById('section-broadcast').classList.toggle('d-none', tab !== 'broadcast');
    document.getElementById('section-files').classList.toggle('d-none', tab !== 'files');
    document.getElementById('section-manual-triggers').classList.toggle('d-none', tab !== 'manual-triggers');

    document.getElementById('tab-broadcast').classList.toggle('active', tab === 'broadcast');
    document.getElementById('tab-files').classList.toggle('active', tab === 'files');
    document.getElementById('tab-manual-triggers').classList.toggle('active', tab === 'manual-triggers');

    alertBox.classList.add('d-none');
}

document.getElementById('broadcastForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    setLoading(true, "Sending...");

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
        showAlert("success", "✅ Broadcast Sent!");
        document.getElementById('broadcastForm').reset();
    } catch (err) {
        handleAuthError(err);
    } finally {
        setLoading(false, "🚀 Send Broadcast", "sendBtn");
    }
});

document.getElementById('fileInput').addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (file) document.getElementById('filenameInput').value = file.name;
});

document.getElementById('uploadForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    setLoading(true, "Uploading... (This may take a minute)", "uploadBtn");

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
            showAlert("success", `✅ Uploaded to ${res.path}. Processing started.`);
            document.getElementById('uploadForm').reset();
        } catch (err) {
            handleAuthError(err);
        } finally {
            setLoading(false, "⬆️ Upload File", "uploadBtn");
        }
    };
});

async function triggerFunction(functionName) {
    setLoading(true, `Triggering ${functionName}...`, `trigger-${functionName}`);
    try {
        const res = await postData(`${BASE_URL}/${functionName}`, { secret: currentKey });
        showAlert("success", `✅ ${functionName} triggered successfully!`);
    } catch (err) {
        handleAuthError(err);
    } finally {
        setLoading(false, `Trigger ${functionName}`, `trigger-${functionName}`);
    }
}

async function postData(url, data) {
    const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ data: data })
    });
    const json = await res.json();
    if (!res.ok || json.error) throw new Error(json.error?.message || "Request Failed");
    return json.result || json;
}

function setLoading(isLoading, text, btnId = "sendBtn") {
    const btn = document.getElementById(btnId);
    if (btn) {
        btn.disabled = isLoading;
        btn.innerText = text;
    }
}

function showAlert(type, msg) {
    alertBox.className = `alert alert-${type}`;
    alertBox.innerText = msg;
    alertBox.classList.remove('d-none');
}

function handleAuthError(err) {
    if (err.message.includes("Invalid") || err.message.includes("UNAUTHENTICATED")) {
        logout();
        document.getElementById('loginError').textContent = "Session expired. Please login again.";
        document.getElementById('loginError').classList.remove('d-none');
    } else {
        showAlert("danger", "❌ Error: " + err.message);
    }
}
