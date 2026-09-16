let lastMessageCount = 0;

async function fetchMessages() {
    try {
        const res = await fetch('/api/messages');
        const messages = await res.json();
        
        if (messages.length !== lastMessageCount) {
            lastMessageCount = messages.length;
            renderMessages(messages);
        }
    } catch (err) {
        console.error("Failed to fetch messages", err);
    }
}

function renderMessages(messages) {
    const container = document.getElementById('chat-messages');
    const currentUsername = document.getElementById('username-input').value || 'You';
    
    container.innerHTML = messages.map(m => {
        const isMe = m.sender === currentUsername;
        const timeStr = new Date(m.timestamp * 1000).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        
        return `
            <div class="message-bubble ${isMe ? 'me' : 'other'}">
                ${!isMe ? `<div class="msg-sender">${m.sender}</div>` : ''}
                <div class="msg-text">${escapeHtml(m.text)}</div>
                <div class="msg-time">${timeStr}</div>
            </div>
        `;
    }).join('');
    
    container.scrollTop = container.scrollHeight;
}

function escapeHtml(text) {
    return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

document.getElementById('chat-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const input = document.getElementById('message-input');
    const sender = document.getElementById('username-input').value || 'You';
    const text = input.value.trim();
    
    if (!text) return;
    
    input.value = '';
    
    await fetch('/api/messages/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ sender, text })
    });
    
    fetchMessages();
});

// Share Modal handling
document.getElementById('share-btn').addEventListener('click', () => {
    const modal = document.getElementById('share-modal');
    const qrContainer = document.getElementById('qrcode');
    const urlInput = document.getElementById('share-url');
    
    qrContainer.innerHTML = '';
    const currentUrl = window.location.href;
    urlInput.value = currentUrl;
    
    new QRCode(qrContainer, {
        text: currentUrl,
        width: 130,
        height: 130,
        colorDark: "#000000",
        colorLight: "#ffffff",
        correctLevel: QRCode.CorrectLevel.H
    });

    modal.classList.remove('hidden');
});

document.getElementById('close-modal').addEventListener('click', () => {
    document.getElementById('share-modal').classList.add('hidden');
});

// Poll for new messages every 1.5 seconds
setInterval(fetchMessages, 1500);
fetchMessages();
