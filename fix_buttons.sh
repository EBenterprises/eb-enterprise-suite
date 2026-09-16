#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Action Button Spacing & Layout Optimization
# ==============================================================================
set -e

cd eb-sales-tracker

echo "[+] Updating styles.css to give status controls and buttons breathing room..."
cat << 'CSS_EOF' > public/styles.css
:root {
    --obsidian: #05070b;
    --dark-grey: #0f172a;
    --card-bg: rgba(15, 23, 42, 0.75);
    --border-color: #1e293b;
    --deep-teal: #0284c7;
    --teal-glow: #38bdf8;
    --champagne-gold: #fbbf24;
    --gold-glow: rgba(251, 191, 36, 0.3);
    --text-main: #f8fafc;
    --text-muted: #94a3b8;
    --danger: #ef4444;
    --danger-hover: #dc2626;
    --success: #10b981;
    --warning: #f59e0b;
}

* { box-sizing: border-box; margin: 0; padding: 0; font-family: 'JetBrains Mono', monospace, -apple-system, sans-serif; }

body {
    background-color: var(--obsidian);
    background-image: 
        radial-gradient(circle at 15% 10%, rgba(2, 132, 199, 0.1) 0%, transparent 45%),
        radial-gradient(circle at 85% 90%, rgba(251, 191, 36, 0.07) 0%, transparent 45%);
    color: var(--text-main);
    padding: 30px;
    line-height: 1.6;
    min-height: 100vh;
}

.container { max-width: 1400px; margin: 0 auto; }

header {
    text-align: center; margin-bottom: 35px; border-bottom: 1px solid var(--border-color); padding-bottom: 25px;
    position: relative;
}

.logo {
    display: inline-block; width: 65px; height: 65px; line-height: 65px;
    background: linear-gradient(135deg, var(--deep-teal), #0369a1); color: var(--text-main);
    font-weight: 900; font-size: 2rem; border-radius: 14px; margin-bottom: 12px;
    box-shadow: 0 0 25px rgba(56, 189, 248, 0.4);
    border: 1px solid var(--teal-glow);
}

h1 { color: var(--teal-glow); font-size: 2.6rem; letter-spacing: 2px; text-transform: uppercase; text-shadow: 0 0 20px rgba(56, 189, 248, 0.3); }
header p { color: var(--text-muted); font-size: 1.05rem; margin-bottom: 15px; }

.header-actions { display: flex; justify-content: center; gap: 12px; flex-wrap: wrap; margin-top: 15px; }
.btn-action {
    background: rgba(30, 41, 59, 0.8); border: 1px solid var(--border-color); color: var(--text-muted);
    padding: 8px 14px; border-radius: 6px; font-size: 0.8rem; font-weight: 700; cursor: pointer;
    transition: all 0.2s ease; text-transform: uppercase;
}
.btn-action:hover { border-color: var(--teal-glow); color: var(--teal-glow); box-shadow: 0 0 10px rgba(56, 189, 248, 0.2); }

.dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 25px; margin-bottom: 35px; }
.card { 
    background: var(--card-bg); backdrop-filter: blur(16px);
    padding: 25px; border: 1px solid var(--border-color); border-radius: 12px; 
    border-left: 6px solid var(--deep-teal);
    box-shadow: 0 10px 30px rgba(0,0,0,0.6);
    transition: transform 0.2s ease, border-color 0.2s ease;
}
.card:hover { transform: translateY(-3px); border-color: var(--teal-glow); }
.card h3 { color: var(--text-muted); font-size: 0.8rem; text-transform: uppercase; margin-bottom: 10px; letter-spacing: 1px; font-weight: 700; }
.card p { font-size: 2.3rem; font-weight: 800; color: var(--text-main); }

.gold-text { color: var(--champagne-gold) !important; text-shadow: 0 0 12px var(--gold-glow); }
.teal-text { color: var(--teal-glow) !important; text-shadow: 0 0 12px rgba(56, 189, 248, 0.3); }

.form-section, .table-section { 
    background: var(--card-bg); backdrop-filter: blur(16px);
    padding: 30px; border: 1px solid var(--border-color); margin-bottom: 35px; border-radius: 12px; 
    box-shadow: 0 15px 35px rgba(0,0,0,0.7);
}

.section-header-flex { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 15px; margin-bottom: 25px; }
h2 { color: var(--teal-glow); font-size: 1.4rem; text-transform: uppercase; letter-spacing: 1px; border-left: 4px solid var(--champagne-gold); padding-left: 12px; }

.search-input {
    background: var(--obsidian); border: 1px solid var(--border-color); color: var(--text-main);
    padding: 10px 14px; border-radius: 8px; font-size: 0.9rem; width: 260px;
    transition: all 0.2s ease;
}
.search-input:focus { outline: none; border-color: var(--teal-glow); box-shadow: 0 0 12px rgba(56, 189, 248, 0.25); }

.form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(190px, 1fr)); gap: 20px; margin-bottom: 25px; }
.form-group { display: flex; flex-direction: column; }
.form-group label { font-size: 0.8rem; margin-bottom: 8px; color: var(--text-muted); font-weight: 700; text-transform: uppercase; }
.form-group input, .form-group select { 
    padding: 14px; background: var(--obsidian); border: 1px solid var(--border-color); 
    color: var(--text-main); font-size: 1rem; border-radius: 8px; 
    transition: all 0.2s ease;
}
.form-group input::placeholder { color: #475569; }
.form-group input:focus, .form-group select:focus { 
    outline: none; border-color: var(--teal-glow); 
    box-shadow: 0 0 15px rgba(56, 189, 248, 0.25); 
    background: #0f172a;
}

.btn-submit { 
    width: 100%; padding: 16px; 
    background: linear-gradient(135deg, var(--deep-teal), #0369a1); 
    color: var(--text-main); border: 1px solid var(--teal-glow); 
    font-weight: 800; font-size: 1.1rem; cursor: pointer; border-radius: 8px; 
    text-transform: uppercase; letter-spacing: 1.5px;
    box-shadow: 0 4px 20px rgba(2, 132, 199, 0.4);
    transition: all 0.2s ease; 
}
.btn-submit:hover { 
    background: linear-gradient(135deg, #0369a1, var(--deep-teal));
    box-shadow: 0 6px 25px rgba(56, 189, 248, 0.6);
    transform: translateY(-2px);
}

.table-wrapper { overflow-x: auto; border-radius: 8px; border: 1px solid var(--border-color); }
table { width: 100%; border-collapse: collapse; text-align: left; }
th, td { padding: 20px 16px; border-bottom: 1px solid var(--border-color); vertical-align: middle; }
th { color: var(--text-muted); text-transform: uppercase; font-size: 0.75rem; letter-spacing: 1px; background: #0f172a; font-weight: 800; }
td { font-size: 0.95rem; color: var(--text-main); }
tbody tr { transition: background 0.15s ease; }
tbody tr:hover { background: rgba(30, 41, 59, 0.5); }

.badge { padding: 8px 14px; border-radius: 6px; font-size: 0.75rem; font-weight: 800; text-transform: uppercase; display: inline-block; box-shadow: 0 2px 10px rgba(0,0,0,0.3); }
.badge-paid { background: rgba(16, 185, 129, 0.2); color: #34d399; border: 1px solid #10b981; }
.badge-unpaid { background: rgba(239, 68, 68, 0.2); color: #f87171; border: 1px solid #ef4444; }
.badge-partial { background: rgba(245, 158, 11, 0.2); color: #fbbf24; border: 1px solid #f59e0b; }

.status-controls { display: flex; flex-direction: column; gap: 10px; min-width: 150px; }
select.status-select { 
    padding: 8px 12px; background: var(--obsidian); color: var(--text-main); 
    border: 1px solid var(--border-color); border-radius: 6px; font-size: 0.85rem; font-weight: 600;
    cursor: pointer; width: 100%;
}
input.paid-input { 
    padding: 8px 12px; background: var(--obsidian); color: var(--champagne-gold); 
    border: 1px solid var(--border-color); border-radius: 6px; font-size: 0.85rem; width: 100%; font-weight: bold;
}

.tab-action-container { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; margin-top: 6px; }

.btn-settle {
    background: rgba(16, 185, 129, 0.2); border: 1px solid var(--success); color: #34d399;
    padding: 8px 16px; cursor: pointer; border-radius: 6px; font-weight: 700; font-size: 0.75rem;
    text-transform: uppercase; transition: all 0.2s ease; letter-spacing: 0.5px;
}
.btn-settle:hover { background: var(--success); color: white; box-shadow: 0 0 15px rgba(16, 185, 129, 0.5); }

.btn-delete { 
    background: rgba(239, 68, 68, 0.15); border: 1px solid var(--danger); color: #f87171; 
    padding: 10px 16px; cursor: pointer; border-radius: 6px; font-weight: 700; font-size: 0.8rem;
    text-transform: uppercase; transition: all 0.2s ease; letter-spacing: 0.5px;
}
.btn-delete:hover { background: var(--danger); color: white; box-shadow: 0 0 15px rgba(239, 68, 68, 0.4); }
CSS_EOF

echo "[+] Updating app.js to cleanly stack customer tab status badges and action buttons..."
cat << 'JS_EOF' > public/app.js
const API_URL = '/api/sales';

const salesForm = document.getElementById('salesForm');
const customerNameInput = document.getElementById('customerName');
const itemNameInput = document.getElementById('itemName');
const unitPriceInput = document.getElementById('unitPrice');
const quantityInput = document.getElementById('quantity');
const weightGramsInput = document.getElementById('weightGrams');
const paymentStatusInput = document.getElementById('paymentStatus');
const amountPaidGroup = document.getElementById('amountPaidGroup');
const amountPaidInput = document.getElementById('amountPaid');

const salesTableBody = document.getElementById('salesTableBody');
const customerTabsTableBody = document.getElementById('customerTabsTableBody');

const totalRevenueEl = document.getElementById('totalRevenue');
const totalWeightEl = document.getElementById('totalWeight');
const totalSalesEl = document.getElementById('totalSales');

const customerSearch = document.getElementById('customerSearch');
const transactionSearch = document.getElementById('transactionSearch');

const toggleAudioBtn = document.getElementById('toggleAudioBtn');
const exportCsvBtn = document.getElementById('exportCsvBtn');
const exportJsonBtn = document.getElementById('exportJsonBtn');
const importJsonBtn = document.getElementById('importJsonBtn');
const importFile = document.getElementById('importFile');

let audioEnabled = true;
let currentSalesData = [];

// Web Audio API Synthesizer
const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
function playSynthSound(type) {
    if (!audioEnabled) return;
    if (audioCtx.state === 'suspended') audioCtx.resume();
    
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.connect(gain);
    gain.connect(audioCtx.destination);

    if (type === 'click') {
        osc.frequency.setValueAtTime(440, audioCtx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(220, audioCtx.currentTime + 0.05);
        gain.gain.setValueAtTime(0.05, audioCtx.currentTime);
        gain.gain.linearRampToValueAtTime(0.01, audioCtx.currentTime + 0.05);
        osc.start();
        osc.stop(audioCtx.currentTime + 0.05);
    } else if (type === 'success') {
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(523.25, audioCtx.currentTime);
        osc.frequency.setValueAtTime(659.25, audioCtx.currentTime + 0.08);
        osc.frequency.setValueAtTime(783.99, audioCtx.currentTime + 0.16);
        gain.gain.setValueAtTime(0.08, audioCtx.currentTime);
        gain.gain.linearRampToValueAtTime(0.01, audioCtx.currentTime + 0.3);
        osc.start();
        osc.stop(audioCtx.currentTime + 0.3);
    }
}

toggleAudioBtn.addEventListener('click', () => {
    audioEnabled = !audioEnabled;
    toggleAudioBtn.textContent = audioEnabled ? '🔊 Audio: ON' : '🔇 Audio: OFF';
    playSynthSound('click');
});

document.addEventListener('DOMContentLoaded', fetchAndRecord);

async function fetchAndRecord() {
    try {
        const res = await fetch(API_URL);
        currentSalesData = await res.json();
        render(currentSalesData);
    } catch (err) {
        console.error("API Failure:", err);
    }
}

paymentStatusInput.addEventListener('change', (e) => {
    playSynthSound('click');
    if (e.target.value === 'partial' || e.target.value === 'paid') {
        amountPaidGroup.style.display = 'flex';
        if (e.target.value === 'paid') {
            const unitPrice = parseFloat(unitPriceInput.value) || 0;
            const qty = parseInt(quantityInput.value) || 1;
            amountPaidInput.value = (unitPrice * qty).toFixed(2);
        }
    } else {
        amountPaidGroup.style.display = 'none';
        amountPaidInput.value = '';
    }
});

salesForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    playSynthSound('success');
    const status = paymentStatusInput.value;
    let amountPaid = 0;
    if (status === 'paid') {
        amountPaid = parseFloat(unitPriceInput.value) * parseInt(quantityInput.value, 10);
    } else if (status === 'partial') {
        amountPaid = parseFloat(amountPaidInput.value) || 0;
    }

    const payload = {
        date: new Date().toISOString().replace('T', ' ').substring(0, 19),
        customer: customerNameInput.value.trim(),
        name: itemNameInput.value.trim(),
        price: parseFloat(unitPriceInput.value),
        quantity: parseInt(quantityInput.value, 10),
        weightGrams: parseFloat(weightGramsInput.value),
        status: status,
        amountPaid: amountPaid
    };

    await fetch(API_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    });

    salesForm.reset();
    quantityInput.value = '1';
    paymentStatusInput.value = 'unpaid';
    amountPaidGroup.style.display = 'none';
    amountPaidInput.value = '';
    fetchAndRecord();
});

async function updateTransaction(id, newStatus, currentTotalVal, currentAmountPaidInputEl) {
    playSynthSound('click');
    const statusVal = newStatus;
    let paidVal = parseFloat(currentAmountPaidInputEl.value) || 0;

    if (statusVal === 'paid') {
        paidVal = currentTotalVal;
    } else if (statusVal === 'unpaid') {
        paidVal = 0;
    }

    await fetch(`${API_URL}/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: statusVal, amountPaid: paidVal })
    });
    fetchAndRecord();
}

async function settleCustomerTab(customerName) {
    playSynthSound('success');
    await fetch(`/api/settle-customer/${encodeURIComponent(customerName)}`, {
        method: 'PUT'
    });
    fetchAndRecord();
}

async function deleteEntry(id) {
    playSynthSound('click');
    await fetch(`${API_URL}/${id}`, { method: 'DELETE' });
    fetchAndRecord();
}

customerSearch.addEventListener('input', () => render(currentSalesData));
transactionSearch.addEventListener('input', () => render(currentSalesData));

function render(sales) {
    salesTableBody.innerHTML = '';
    customerTabsTableBody.innerHTML = '';
    
    let grandRevenue = 0, grandWeight = 0;
    const customerMap = {};

    const custQuery = customerSearch.value.toLowerCase();
    const txQuery = transactionSearch.value.toLowerCase();

    sales.forEach(sale => {
        const rowTotalWeight = sale.weightGrams * sale.quantity;
        const rowTotalPrice = sale.price * sale.quantity;
        const salePaid = typeof sale.amountPaid === 'number' ? sale.amountPaid : (sale.status === 'paid' ? rowTotalPrice : 0);
        
        grandRevenue += rowTotalPrice;
        grandWeight += rowTotalWeight;

        const custName = sale.customer || 'N/A';
        if (!customerMap[custName]) {
            customerMap[custName] = {
                name: custName,
                txCount: 0,
                totalMass: 0,
                totalBill: 0,
                totalPaid: 0,
                items: []
            };
        }
        customerMap[custName].txCount += 1;
        customerMap[custName].totalMass += rowTotalWeight;
        customerMap[custName].totalBill += rowTotalPrice;
        customerMap[custName].totalPaid += salePaid;
        customerMap[custName].items.push(sale);
    });

    const filteredSales = sales.filter((sale, index) => {
        const textToSearch = `#${index + 1} ${sale.date} ${sale.customer} ${sale.name} ${sale.status}`.toLowerCase();
        return textToSearch.includes(txQuery);
    });

    if (filteredSales.length === 0) {
        salesTableBody.innerHTML = `<tr><td colspan="11" style="text-align: center; color: var(--text-muted); padding: 25px;">No matching transactions found.</td></tr>`;
    } else {
        filteredSales.forEach((sale) => {
            const originalIndex = sales.indexOf(sale);
            const rowNumber = originalIndex + 1;
            const rowTotalWeight = sale.weightGrams * sale.quantity;
            const rowTotalPrice = sale.price * sale.quantity;
            const salePaid = typeof sale.amountPaid === 'number' ? sale.amountPaid : (sale.status === 'paid' ? rowTotalPrice : 0);

            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td><strong style="color: var(--teal-glow);">#${rowNumber}</strong></td>
                <td>${sale.date}</td>
                <td><strong class="gold-text">${escapeHtml(sale.customer || 'N/A')}</strong></td>
                <td><strong>${escapeHtml(sale.name)}</strong></td>
                <td>$${sale.price.toFixed(2)}</td>
                <td>${sale.quantity}</td>
                <td>${sale.weightGrams.toFixed(2)}</td>
                <td class="teal-text">${rowTotalWeight.toFixed(2)} g</td>
                <td class="gold-text">$${rowTotalPrice.toFixed(2)}</td>
                <td>
                    <div class="status-controls">
                        <select class="status-select" id="status-${sale.id}" onchange="handleStatusChange(${sale.id}, ${rowTotalPrice})">
                            <option value="unpaid" ${sale.status === 'unpaid' ? 'selected' : ''}>Unpaid</option>
                            <option value="partial" ${sale.status === 'partial' ? 'selected' : ''}>Partial</option>
                            <option value="paid" ${sale.status === 'paid' ? 'selected' : ''}>Paid</option>
                        </select>
                        <input type="number" class="paid-input" id="paid-input-${sale.id}" step="0.01" min="0" max="${rowTotalPrice}" value="${salePaid.toFixed(2)}" ${sale.status === 'unpaid' ? 'style="display:none;"' : ''} placeholder="Paid $" onchange="updateTransaction(${sale.id}, document.getElementById('status-${sale.id}').value, ${rowTotalPrice}, this)">
                    </div>
                </td>
                <td><button class="btn-delete" onclick="deleteEntry(${sale.id})">DEL</button></td>
            `;
            salesTableBody.appendChild(tr);
        });
    }

    const filteredCustomers = Object.values(customerMap).filter(cust => 
        cust.name.toLowerCase().includes(custQuery)
    );

    if (filteredCustomers.length === 0) {
        customerTabsTableBody.innerHTML = `<tr><td colspan="7" style="text-align: center; color: var(--text-muted); padding: 25px;">No matching customer tabs.</td></tr>`;
    } else {
        filteredCustomers.forEach(cust => {
            const remainingBalance = Math.max(0, cust.totalBill - cust.totalPaid);
            const tr = document.createElement('tr');
            let actionHtml = '';
            if (remainingBalance <= 0.01) {
                actionHtml = '<span class="badge badge-paid">Fully Settled</span>';
            } else if (cust.totalPaid > 0) {
                actionHtml = `
                    <div class="tab-action-container">
                        <span class="badge badge-partial">Partial ($${remainingBalance.toFixed(2)} Due)</span>
                        <button class="btn-settle" onclick="settleCustomerTab('${escapeQuote(cust.name)}')">Settle Tab</button>
                    </div>
                `;
            } else {
                actionHtml = `
                    <div class="tab-action-container">
                        <span class="badge badge-unpaid">Unpaid Tab</span>
                        <button class="btn-settle" onclick="settleCustomerTab('${escapeQuote(cust.name)}')">Settle Tab</button>
                    </div>
                `;
            }

            tr.innerHTML = `
                <td><strong class="gold-text">${escapeHtml(cust.name)}</strong></td>
                <td>${cust.txCount} tx</td>
                <td class="teal-text">${cust.totalMass.toFixed(2)} g</td>
                <td class="gold-text">$${cust.totalBill.toFixed(2)}</td>
                <td style="color: var(--success);">$${cust.totalPaid.toFixed(2)}</td>
                <td style="color: ${remainingBalance > 0 ? 'var(--danger)' : 'var(--success)'}; font-weight: bold;">$${remainingBalance.toFixed(2)}</td>
                <td>${actionHtml}</td>
            `;
            customerTabsTableBody.appendChild(tr);
        });
    }

    totalRevenueEl.textContent = `$${grandRevenue.toFixed(2)}`;
    totalWeightEl.textContent = `${grandWeight.toFixed(2)} g`;
    totalSalesEl.textContent = sales.length;
}

function handleStatusChange(id, totalVal) {
    const statusSelect = document.getElementById(`status-${id}`);
    const paidInput = document.getElementById(`paid-input-${id}`);
    
    if (statusSelect.value === 'paid') {
        paidInput.value = totalVal.toFixed(2);
        paidInput.style.display = 'block';
    } else if (statusSelect.value === 'partial') {
        paidInput.style.display = 'block';
        if (parseFloat(paidInput.value) >= totalVal || parseFloat(paidInput.value) === 0) {
            paidInput.value = (totalVal / 2).toFixed(2);
        }
    } else {
        paidInput.value = '0.00';
        paidInput.style.display = 'none';
    }

    updateTransaction(id, statusSelect.value, totalVal, paidInput);
}

exportCsvBtn.addEventListener('click', () => {
    playSynthSound('click');
    if (currentSalesData.length === 0) return alert('No data to export.');
    let csv = 'ID,Date,Customer,Asset,UnitPrice,Quantity,WeightPerUnit,TotalMass,TotalValue,Status,AmountPaid\n';
    currentSalesData.forEach(s => {
        csv += `${s.id},"${s.date}","${s.customer}","${s.name}",${s.price},${s.quantity},${s.weightGrams},${s.weightGrams * s.quantity},${s.price * s.quantity},${s.status},${s.amountPaid}\n`;
    });
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `eb-sales-ledger-${new Date().toISOString().substring(0,10)}.csv`;
    a.click();
});

exportJsonBtn.addEventListener('click', () => {
    playSynthSound('click');
    const blob = new Blob([JSON.stringify(currentSalesData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `eb-database-backup-${new Date().toISOString().substring(0,10)}.json`;
    a.click();
});

importJsonBtn.addEventListener('click', () => {
    playSynthSound('click');
    importFile.click();
});

importFile.addEventListener('change', async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = async function(event) {
        try {
            const json = JSON.parse(event.target.result);
            await fetch('/api/backup', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(json)
            });
            fetchAndRecord();
            alert('Database successfully restored!');
        } catch (err) {
            alert('Invalid backup file format.');
        }
    };
    reader.readAsText(file);
});

function escapeHtml(str) {
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
}

function escapeQuote(str) {
    return str.replace(/'/g, "\\'");
}
JS_EOF

echo "[+] Layout padding and button spacing optimized. Restarting server..."
node server.js
