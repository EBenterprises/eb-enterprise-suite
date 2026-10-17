// --- EB Enterprises® Incremental Update Script ---
const fs = require('fs');
const path = require('path');

// 1. Update backend server.js to enforce reverse chronological sorting
const serverPath = path.join(__dirname, 'server.js');
if (fs.existsSync(serverPath)) {
    let serverContent = fs.readFileSync(serverPath, 'utf8');
    const sortingSnippet = `
// --- INJECTED UPDATE: Reverse Chronological Sorting ---
function saveTransactions(transactions) {
    transactions.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    fs.writeFileSync(DATA_FILE, JSON.stringify(transactions, null, 2));
}

app.get('/api/transactions', (req, res) => {
    let txs = getTransactions();
    txs.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    res.json(txs);
});
`;
    if (!serverContent.includes('Reverse Chronological Sorting')) {
        fs.appendFileSync(serverPath, sortingSnippet);
        console.log('Successfully updated server.js with reverse chronological sorting.');
    } else {
        console.log('server.js already contains sorting logic.');
    }
}

// 2. Update frontend app.js to handle dynamic itemized rows and calculation
const appJsPath = path.join(__dirname, 'public', 'app.js');
if (fs.existsSync(appJsPath)) {
    let appContent = fs.readFileSync(appJsPath, 'utf8');
    const clientSnippet = `
// --- INJECTED UPDATE: Dynamic Item Rows & Total Calculation ---
const itemsContainer = document.getElementById('items-container');
const addItemBtn = document.getElementById('add-item-btn');
const calculatedTotal = document.getElementById('calculated-total');

function calculateTotal() {
    let total = 0;
    document.querySelectorAll('.item-row').forEach(row => {
        const qty = parseFloat(row.querySelector('.item-qty').value) || 0;
        const price = parseFloat(row.querySelector('.item-price').value) || 0;
        total += qty * price;
    });
    if (calculatedTotal) calculatedTotal.textContent = \`$\${total.toFixed(2)}\`;
    return total;
}

if (addItemBtn) {
    addItemBtn.addEventListener('click', () => {
        const row = document.createElement('div');
        row.className = 'item-row';
        row.innerHTML = \`
            <input type="text" placeholder="Item Name" class="item-name" required>
            <input type="number" placeholder="Qty" class="item-qty" value="1" min="1" required>
            <input type="number" placeholder="Price ($)" class="item-price" step="0.01" required>
            <button type="button" class="remove-item-btn">×</button>
        \`;
        itemsContainer.appendChild(row);
        attachRowListeners(row);
    });
}

function attachRowListeners(row) {
    const removeBtn = row.querySelector('.remove-item-btn');
    if (removeBtn) {
        removeBtn.addEventListener('click', () => {
            if (document.querySelectorAll('.item-row').length > 1) {
                row.remove();
                calculateTotal();
            } else {
                alert('You must have at least one item.');
            }
        });
    }
    row.querySelectorAll('input').forEach(input => {
        input.addEventListener('input', calculateTotal);
    });
}

document.querySelectorAll('.item-row').forEach(attachRowListeners);
`;
    if (!appContent.includes('Dynamic Item Rows')) {
        fs.appendFileSync(appJsPath, clientSnippet);
        console.log('Successfully updated app.js with itemized row logic.');
    } else {
        console.log('app.js already contains itemized row logic.');
    }
}
