const state = {
    myNumber: "+1 (555) 010-9988", // Pre-provisioned so inputs are open immediately
    activeContact: { id: 1, name: "Vance Sterling", number: "+1 (555) 019-2834", status: "Cellular" },
    contacts: [
        { id: 1, name: "Vance Sterling", number: "+1 (555) 019-2834", status: "Cellular" },
        { id: 2, name: "Lyra Vane", number: "+1 (555) 014-9921", status: "Mobile Gateway" },
        { id: 3, name: "Emergency Broadcast", number: "+1 (800) 555-0000", status: "Carrier Node" }
    ],
    messages: {
        1: [
            { sender: 'received', type: 'sms', text: 'Secure carrier link active over SMS channel.', timestamp: '12:00 PM' }
        ],
        2: [
            { sender: 'received', type: 'mms', text: 'Incoming carrier payload image asset.', mediaUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400', timestamp: '12:05 PM' }
        ],
        3: [
            { sender: 'received', type: 'sms', text: 'Carrier routing operational. Inputs unlocked.', timestamp: '12:10 PM' }
        ]
    }
};

const phoneDisplayEl = document.getElementById('phoneDisplay');
const provisionBtnEl = document.getElementById('provisionBtn');
const contactListEl = document.getElementById('contactList');
const chatHeaderEl = document.getElementById('chatHeader');
const messageStreamEl = document.getElementById('messageStream');
const messageInputEl = document.getElementById('messageInput');
const mmsInputEl = document.getElementById('mmsInput');
const mmsToggleBtnEl = document.getElementById('mmsToggleBtn');
const sendBtnEl = document.getElementById('sendBtn');

let mmsMode = false;

function init() {
    phoneDisplayEl.textContent = state.myNumber;
    provisionBtnEl.textContent = "Number Active ✓";
    provisionBtnEl.style.background = "#10b981";
    
    renderContacts();
    selectContact(state.contacts[0]);
    setupListeners();
}

function renderContacts() {
    contactListEl.innerHTML = '';
    state.contacts.forEach(contact => {
        const div = document.createElement('div');
        div.className = `contact-item ${state.activeContact?.id === contact.id ? 'active' : ''}`;
        div.innerHTML = `<strong>${contact.name}</strong><br><small style="color:var(--text-muted);">${contact.number}</small>`;
        div.onclick = () => selectContact(contact);
        contactListEl.appendChild(div);
    });
}

function selectContact(contact) {
    state.activeContact = contact;
    chatHeaderEl.innerHTML = `${contact.name} <span style="font-size:0.8rem; color:var(--text-muted); font-family:monospace;">(${contact.number})</span>`;
    renderContacts();
    renderMessages();
}

function renderMessages() {
    messageStreamEl.innerHTML = '';
    const msgs = state.messages[state.activeContact.id] || [];
    msgs.forEach(msg => {
        const div = document.createElement('div');
        div.className = `message ${msg.sender}`;
        
        let content = `<div>${msg.text}</div>`;
        if (msg.type === 'mms' && msg.mediaUrl) {
            content += `<img src="${msg.mediaUrl}" alt="MMS Attachment" onerror="this.style.display='none'">`;
        }
        content += `<div style="font-size:0.7rem; color:inherit; opacity:0.7; margin-top:6px; text-align:right;">${msg.timestamp}</div>`;
        
        div.innerHTML = content;
        messageStreamEl.appendChild(div);
    });
    messageStreamEl.scrollTop = messageStreamEl.scrollHeight;
}

function sendMessage() {
    const text = messageInputEl.value.trim();
    const mediaUrl = mmsInputEl.value.trim();
    if (!text && !mediaUrl) return;
    if (!state.activeContact) return;

    if (!state.messages[state.activeContact.id]) {
        state.messages[state.activeContact.id] = [];
    }

    const type = mediaUrl ? 'mms' : 'sms';
    const timestamp = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    state.messages[state.activeContact.id].push({
        sender: 'sent',
        type: type,
        text: text || (mediaUrl ? '[MMS Attachment]' : ''),
        mediaUrl: mediaUrl || null,
        timestamp: timestamp
    });

    messageInputEl.value = '';
    mmsInputEl.value = '';
    if (mmsMode) toggleMmsMode();
    renderMessages();

    setTimeout(() => {
        const replyType = Math.random() > 0.5 ? 'mms' : 'sms';
        const replyMedia = replyType === 'mms' ? 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=400' : null;
        state.messages[state.activeContact.id].push({
            sender: 'received',
            type: replyType,
            text: `[Carrier Gateway Echo]: Received ${replyType.toUpperCase()} transmission.`,
            mediaUrl: replyMedia,
            timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        });
        renderMessages();
    }, 1000);
}

function toggleMmsMode() {
    mmsMode = !mmsMode;
    if (mmsMode) {
        mmsInputEl.style.display = 'block';
        mmsToggleBtnEl.style.background = '#4f46e5';
        mmsInputEl.focus();
    } else {
        mmsInputEl.style.display = 'none';
        mmsToggleBtnEl.style.background = '';
    }
}

function setupListeners() {
    provisionBtnEl.onclick = () => {
        const areaCode = Math.floor(200 + Math.random() * 799);
        const exchange = Math.floor(200 + Math.random() * 799);
        const line = Math.floor(1000 + Math.random() * 8999);
        state.myNumber = `+1 (${areaCode}) ${exchange}-${line}`;
        phoneDisplayEl.textContent = state.myNumber;
    };
    sendBtnEl.onclick = sendMessage;
    mmsToggleBtnEl.onclick = toggleMmsMode;
    messageInputEl.onkeydown = (e) => { if (e.key === 'Enter') sendMessage(); };
    mmsInputEl.onkeydown = (e) => { if (e.key === 'Enter') sendMessage(); };
}

init();
