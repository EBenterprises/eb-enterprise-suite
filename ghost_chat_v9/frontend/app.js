let authToken = localStorage.getItem('ghost_token');
let currentUsername = localStorage.getItem('ghost_user');
let activeRecipient = null;
let allMessages = [];
let allUsers = [];

if (authToken && currentUsername) {
    bootApp();
}

function switchAuthTab(tab) {
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    event.target.classList.add('active');
    const btn = document.getElementById('auth-submit-btn');
    btn.innerText = tab === 'login' ? 'Sign In' : 'Create Account';
}

async function handleAuth(e) {
    e.preventDefault();
    const username = document.getElementById('auth-user').value.trim();
    const password = document.getElementById('auth-pass').value;
    const isLogin = document.querySelector('.tab-btn.active').innerText.includes('Sign In');
    const endpoint = isLogin ? '/api/auth/login' : '/api/auth/register';

    const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password })
    });
    const data = await res.json();
    if (res.ok) {
        saveSession(data.token, data.username);
    } else {
        alert(data.error);
    }
}

function saveSession(token, username) {
    localStorage.setItem('ghost_token', token);
    localStorage.setItem('ghost_user', username);
    authToken = token;
    currentUsername = username;
    bootApp();
}

function bootApp() {
    document.getElementById('auth-modal').classList.add('hidden');
    document.getElementById('app-container').classList.remove('hidden');
    document.getElementById('current-user-display').innerText = currentUsername;
    pollData();
    setInterval(pollData, 2000);
}

function logout() {
    localStorage.clear();
    location.reload();
}

async function updateMyStatus(status) {
    await fetch('/api/user/update', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': authToken },
        body: JSON.stringify({ status })
    });
    const dot = document.getElementById('my-status-dot');
    dot.className = `status-dot ${status}`;
}

async function pollData() {
    if (!authToken) return;
    try {
        const [usersRes, msgRes] = await Promise.all([
            fetch('/api/users', { headers: { 'Authorization': authToken } }),
            fetch('/api/messages', { headers: { 'Authorization': authToken } })
        ]);
        if (msgRes.status === 401) { logout(); return; }

        allUsers = await usersRes.json();
        allMessages = await msgRes.json();

        renderContacts();
        if (activeRecipient) {
            renderMessages();
            updateActiveHeaderStatus();
        }
    } catch (err) {
        console.error("Sync error", err);
    }
}

function renderContacts() {
    const list = document.getElementById('contact-list');
    const otherUsers = allUsers.filter(u => u.username !== currentUsername);

    if (otherUsers.length === 0) {
        list.innerHTML = `<div style="padding:20px; text-align:center; color:var(--text-muted); font-size:0.85rem;">No other users. Add someone above!</div>`;
        return;
    }

    list.innerHTML = otherUsers.map(u => `
        <div class="contact-item ${activeRecipient === u.username ? 'active' : ''}" onclick="selectChat('${u.username}')">
            <div class="avatar-wrapper">
                <div class="avatar">${u.username[0].toUpperCase()}</div>
                <span class="status-dot ${u.status}"></span>
            </div>
            <div class="contact-info">
                <span class="contact-name">${u.username}</span>
                <span class="contact-status-text">${u.status}</span>
            </div>
        </div>
    `).join('');
}

function updateActiveHeaderStatus() {
    const userObj = allUsers.find(u => u.username === activeRecipient);
    const dot = document.getElementById('active-status-dot');
    if (userObj) {
        dot.className = `status-dot ${userObj.status}`;
    }
}

function startNewChat() {
    const target = document.getElementById('new-contact-input').value.trim();
    if (!target || target === currentUsername) return;
    document.getElementById('new-contact-input').value = '';
    selectChat(target);
}

function selectChat(username) {
    activeRecipient = username;
    document.getElementById('active-chat-title').innerText = username;
    document.getElementById('chat-form').classList.remove('hidden');
    renderContacts();
    renderMessages();
    updateActiveHeaderStatus();
}

function renderMessages() {
    const container = document.getElementById('chat-messages');
    const thread = allMessages.filter(m => (m.sender === currentUsername && m.recipient === activeRecipient) || (m.sender === activeRecipient && m.recipient === currentUsername));
    
    if (thread.length === 0) {
        container.innerHTML = `<div class="empty-state">No messages with ${activeRecipient} yet. Start typing below!</div>`;
        return;
    }

    container.innerHTML = thread.map(m => {
        const isMe = m.sender === currentUsername;
        const timeStr = new Date(m.timestamp * 1000).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        return `
            <div class="message-bubble ${isMe ? 'me' : 'other'}">
                <div class="msg-text">${escapeHtml(m.text)}</div>
                <div class="msg-time">${timeStr}</div>
            </div>
        `;
    }).join('');
    container.scrollTop = container.scrollHeight;
}

async function sendMessage(e) {
    e.preventDefault();
    const input = document.getElementById('message-input');
    const text = input.value.trim();
    if (!text || !activeRecipient) return;
    input.value = '';

    await fetch('/api/messages/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': authToken },
        body: JSON.stringify({ recipient: activeRecipient, text })
    });
    pollData();
}

function openSettings() {
    document.getElementById('settings-username').value = currentUsername;
    document.getElementById('settings-password').value = '';
    document.getElementById('settings-modal').classList.remove('hidden');
}

async function saveSettings(e) {
    e.preventDefault();
    const newUsername = document.getElementById('settings-username').value.trim();
    const newPassword = document.getElementById('settings-password').value;

    const res = await fetch('/api/user/update', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': authToken },
        body: JSON.stringify({ username: newUsername, password: newPassword })
    });
    const data = await res.json();
    if (res.ok) {
        saveSession(data.token, data.username);
        document.getElementById('settings-modal').classList.add('hidden');
        alert('Settings updated successfully!');
    } else {
        alert(data.error);
    }
}

function escapeHtml(text) {
    return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

// Share Modal
document.getElementById('share-btn').addEventListener('click', () => {
    const modal = document.getElementById('share-modal');
    const qrContainer = document.getElementById('qrcode');
    const urlInput = document.getElementById('share-url');
    qrContainer.innerHTML = '';
    const currentUrl = window.location.origin;
    urlInput.value = currentUrl;
    new QRCode(qrContainer, { text: currentUrl, width: 130, height: 130, colorDark: "#000000", colorLight: "#ffffff", correctLevel: QRCode.CorrectLevel.H });
    modal.classList.remove('hidden');
});
