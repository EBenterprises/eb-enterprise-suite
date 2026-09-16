let authToken = localStorage.getItem('ghost_token');
let currentUsername = localStorage.getItem('ghost_user');
let activeRecipient = null;
let allMessages = [];

if (authToken && currentUsername) {
    bootApp();
}

function switchAuthTab(tab) {
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    document.getElementById('login-form').classList.add('hidden');
    document.getElementById('register-form').classList.add('hidden');
    document.getElementById('otp-form').classList.add('hidden');

    if (tab === 'login') {
        event.target.classList.add('active');
        document.getElementById('login-form').classList.remove('hidden');
    } else if (tab === 'register') {
        event.target.classList.add('active');
        document.getElementById('register-form').classList.remove('hidden');
    } else if (tab === 'otp') {
        event.target.classList.add('active');
        document.getElementById('otp-form').classList.remove('hidden');
    }
}

async function handleLogin(e) {
    e.preventDefault();
    const username = document.getElementById('login-user').value.trim();
    const password = document.getElementById('login-pass').value;

    const res = await fetch('/api/auth/login', {
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

async function handleRegister(e) {
    e.preventDefault();
    const username = document.getElementById('reg-user').value.trim();
    const password = document.getElementById('reg-pass').value;

    const res = await fetch('/api/auth/register', {
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

async function requestOTP() {
    const target = document.getElementById('otp-target').value.trim();
    if (!target) return alert('Enter email or phone');
    const res = await fetch('/api/auth/otp/request', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ target })
    });
    const data = await res.json();
    if (res.ok) {
        alert(`Verification code sent! [Demo Code: ${data.debug_code}]`);
        document.getElementById('otp-code').value = data.debug_code; // auto-fill for frictionless test
    }
}

async function verifyOTP() {
    const target = document.getElementById('otp-target').value.trim();
    const code = document.getElementById('otp-code').value.trim();
    const res = await fetch('/api/auth/otp/verify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ target, code })
    });
    const data = await res.json();
    if (res.ok) {
        saveSession(data.token, data.username);
    } else {
        alert(data.error);
    }
}

async function simulateGoogleLogin() {
    const email = prompt("Enter simulated Google Email (e.g. alice@gmail.com):", "alice@gmail.com");
    if (!email) return;
    const res = await fetch('/api/auth/google', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email })
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
    localStorage.removeItem('ghost_token');
    localStorage.removeItem('ghost_user');
    location.reload();
}

async function pollData() {
    if (!authToken) return;
    try {
        const [usersRes, msgRes] = await Promise.all([
            fetch('/api/users'),
            fetch('/api/messages', { headers: { 'Authorization': authToken } })
        ]);
        if (msgRes.status === 401) { logout(); return; }
        
        const users = await usersRes.json();
        allMessages = await msgRes.json();
        
        renderContacts(users);
        if (activeRecipient) renderMessages();
    } catch (err) {
        console.error("Sync error", err);
    }
}

function renderContacts(users) {
    const list = document.getElementById('contact-list');
    const otherUsers = users.filter(u => u !== currentUsername);
    
    if (otherUsers.length === 0) {
        list.innerHTML = `<div style="padding:20px; text-align:center; color:#65676b; font-size:0.85rem;">No other users yet. Use search above to start a chat!</div>`;
        return;
    }

    list.innerHTML = otherUsers.map(u => `
        <div class="contact-item ${activeRecipient === u ? 'active' : ''}" onclick="selectChat('${u}')">
            <div class="avatar">${u[0].toUpperCase()}</div>
            <div class="contact-name">${u}</div>
        </div>
    `).join('');
}

function startNewChat() {
    const target = document.getElementById('new-contact-input').value.trim();
    if (!target || target === currentUsername) return;
    document.getElementById('new-contact-input').value = '';
    selectChat(target);
}

function selectChat(username) {
    activeRecipient = username;
    document.getElementById('active-chat-title').innerText = `Chat with ${username}`;
    document.getElementById('chat-form').classList.remove('hidden');
    renderContactsWindowHighlight();
    renderMessages();
}

function renderContactsWindowHighlight() {
    document.querySelectorAll('.contact-item').forEach(el => {
        if (el.innerText.trim() === activeRecipient) el.classList.add('active');
        else el.classList.remove('active');
    });
}

function renderMessages() {
    const container = document.getElementById('chat-messages');
    const thread = allMessages.filter(m => (m.sender === currentUsername && m.recipient === activeRecipient) || (m.sender === activeRecipient && m.recipient === currentUsername));
    
    if (thread.length === 0) {
        container.innerHTML = `<div class="empty-state">No messages with ${activeRecipient} yet. Send your first message below!</div>`;
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
