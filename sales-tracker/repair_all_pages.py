from pathlib import Path
import re
import shutil
from datetime import datetime

ROOT = Path("instances")
STAMP = datetime.now().strftime("%Y%m%d-%H%M%S")

CLIENT = r'''
        function switchTab(tab) {
            const tabs = ['new','cust','bals','hist','sets'];
            tabs.forEach(function(t) {
                const tabEl = document.getElementById('tab' + t.charAt(0).toUpperCase() + t.slice(1));
                const viewEl = document.getElementById('view' + t.charAt(0).toUpperCase() + t.slice(1));
                if (tabEl) tabEl.classList.toggle('active', t === tab);
                if (viewEl) viewEl.classList.toggle('active-view', t === tab);
            });

            if (tab === 'cust') {
                loadData().then(function() { renderProfilesList(allCustomersData); });
            } else if (tab === 'bals') {
                loadData().then(function() { renderBalancesList(allCustomersData); });
            } else if (tab === 'hist') {
                loadData().then(function() { renderGlobalHistory(); });
            } else if (tab === 'sets') {
                renderPresetConfig();
            }
        }

        async function loadData() {
            const response = await fetch('/api/data');
            if (!response.ok) throw new Error('Unable to load data');
            const data = await response.json();

            allCustomersData = Array.isArray(data.customers)
                ? data.customers
                : [];

            globalTxData = Array.isArray(data.transactions)
                ? data.transactions
                : [];

            populateCustomerOptions();
            renderPresetButtons();

            return data;
        }

        function populateCustomerOptions() {
            const select = document.getElementById('customerSelect');
            if (!select) return;

            const current = select.value;
            select.innerHTML =
                '<option value="">Select customer</option>' +
                allCustomersData.map(function(c) {
                    const id = c.id != null ? c.id : '';
                    const name = c.name || 'Unnamed customer';
                    return '<option value="' + escapeHtml(String(id)) + '">' +
                        escapeHtml(name) +
                        '</option>';
                }).join('');

            if (current) select.value = current;
        }

        function renderPresetButtons() {
            const container = document.getElementById('presetButtons');
            if (!container) return;

            const presets = Array.isArray(appPresets) ? appPresets : [];

            container.innerHTML = presets.map(function(p, i) {
                return '<button type="button" class="preset-btn" onclick="setCash(' +
                    Number(p.amount || 0) + ')">' +
                    escapeHtml(p.label || ('$' + Number(p.amount || 0).toFixed(2))) +
                    '</button>';
            }).join('');
        }

        function calculate() {
            const qty = parseFloat(document.getElementById('quantity')?.value || '0');
            const price = parseFloat(document.getElementById('price')?.value || '0');
            const total = qty * price;

            const output = document.getElementById('calculatedTotal');
            if (output) output.textContent = '$' + total.toFixed(2);

            return total;
        }

        function setCash(amount) {
            const input = document.getElementById('cashCollected');
            if (input) input.value = Number(amount || 0).toFixed(2);
            updateBalanceDisplay();
        }

        function setCashExact() {
            const total = calculate();
            setCash(total);
        }

        function updateBalanceDisplay() {
            const total = calculate();
            const paid = parseFloat(document.getElementById('cashCollected')?.value || '0');
            const balance = total - paid;
            const output = document.getElementById('balanceDisplay');
            if (output) {
                output.textContent =
                    '$' + balance.toFixed(2);
            }
        }

        function onCustomerInput() {
            const select = document.getElementById('customerSelect');
            const input = document.getElementById('customerName');
            if (select && input && select.value) {
                const c = allCustomersData.find(function(x) {
                    return String(x.id) === String(select.value);
                });
                if (c) input.value = c.name || '';
            }
        }

        async function recordTransaction() {
            const customerSelect = document.getElementById('customerSelect');
            const customerNameInput = document.getElementById('customerName');
            const quantityInput = document.getElementById('quantity');
            const priceInput = document.getElementById('price');
            const cashInput = document.getElementById('cashCollected');
            const itemInput = document.getElementById('item');
            const notesInput = document.getElementById('notes');

            const customerId = customerSelect ? customerSelect.value : '';
            const customerName = customerNameInput ? customerNameInput.value.trim() : '';
            const quantity = parseFloat(quantityInput ? quantityInput.value : '0') || 0;
            const price = parseFloat(priceInput ? priceInput.value : '0') || 0;
            const cashCollected = parseFloat(cashInput ? cashInput.value : '0') || 0;
            const item = itemInput ? itemInput.value.trim() : '';
            const notes = notesInput ? notesInput.value.trim() : '';

            if (!customerName && !customerId) {
                alert('Enter or select a customer.');
                return;
            }

            if (!quantity && !price) {
                alert('Enter a quantity or amount.');
                return;
            }

            const total = quantity * price;

            const payload = {
                customerId: customerId || null,
                customerName: customerName,
                quantity: quantity,
                price: price,
                amount: total,
                cashCollected: cashCollected,
                item: item,
                notes: notes,
                timestamp: new Date().toISOString()
            };

            const response = await fetch('/api/transactions', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify(payload)
            });

            if (!response.ok) {
                const text = await response.text();
                throw new Error(text || 'Transaction failed');
            }

            await loadData();

            if (typeof clearSaleForm === 'function') {
                clearSaleForm();
            } else {
                if (quantityInput) quantityInput.value = '';
                if (priceInput) priceInput.value = '';
                if (cashInput) cashInput.value = '';
                if (itemInput) itemInput.value = '';
                if (notesInput) notesInput.value = '';
            }

            switchTab('hist');
        }

        function renderProfilesList(data) {
            const container = document.getElementById('profilesList');
            if (!container) return;

            const filter = (
                document.getElementById('profileSearch')?.value || ''
            ).toLowerCase();

            const rows = (data || []).filter(function(c) {
                return String(c.name || '').toLowerCase().includes(filter);
            });

            if (!rows.length) {
                container.innerHTML = '<div class="empty-state">No customer profiles found.</div>';
                return;
            }

            container.innerHTML = rows.map(function(c) {
                const txs = Array.isArray(c.transactions) ? c.transactions : [];
                const purchased = txs.reduce(function(sum, t) {
                    return sum + (Number(t.quantity) || 0);
                }, 0);
                const paid = txs.reduce(function(sum, t) {
                    return sum + (Number(t.cashCollected ?? t.paid ?? t.payment) || 0);
                }, 0);
                const billed = txs.reduce(function(sum, t) {
                    return sum + (Number(t.amount ?? t.total) || 0);
                }, 0);
                const balance = billed - paid;

                return '<div class="data-card">' +
                    '<div class="card-title">' + escapeHtml(c.name || 'Unnamed') + '</div>' +
                    '<div class="card-grid">' +
                    '<div><small>Transactions</small><strong>' + txs.length + '</strong></div>' +
                    '<div><small>Quantity</small><strong>' + purchased + '</strong></div>' +
                    '<div><small>Billed</small><strong>$' + billed.toFixed(2) + '</strong></div>' +
                    '<div><small>Paid</small><strong>$' + paid.toFixed(2) + '</strong></div>' +
                    '<div><small>Balance</small><strong>$' + balance.toFixed(2) + '</strong></div>' +
                    '</div>' +
                    (c.phone ? '<div class="muted">' + escapeHtml(c.phone) + '</div>' : '') +
                    (c.notes ? '<div class="muted">' + escapeHtml(c.notes) + '</div>' : '') +
                    '</div>';
            }).join('');
        }

        function renderBalancesList(data) {
            const container = document.getElementById('balancesList');
            if (!container) return;

            const rows = (data || []).map(function(c) {
                const txs = Array.isArray(c.transactions) ? c.transactions : [];
                const billed = txs.reduce(function(sum, t) {
                    return sum + (Number(t.amount ?? t.total) || 0);
                }, 0);
                const paid = txs.reduce(function(sum, t) {
                    return sum + (Number(t.cashCollected ?? t.paid ?? t.payment) || 0);
                }, 0);
                return {
                    customer: c,
                    billed: billed,
                    paid: paid,
                    balance: billed - paid
                };
            }).filter(function(x) {
                return Math.abs(x.balance) > 0.005;
            });

            if (!rows.length) {
                container.innerHTML = '<div class="empty-state">No outstanding balances.</div>';
                return;
            }

            container.innerHTML = rows.map(function(x) {
                return '<div class="data-card">' +
                    '<div class="card-title">' + escapeHtml(x.customer.name || 'Unnamed') + '</div>' +
                    '<div class="card-grid">' +
                    '<div><small>Billed</small><strong>$' + x.billed.toFixed(2) + '</strong></div>' +
                    '<div><small>Paid</small><strong>$' + x.paid.toFixed(2) + '</strong></div>' +
                    '<div><small>Outstanding</small><strong>$' + x.balance.toFixed(2) + '</strong></div>' +
                    '</div>' +
                    '</div>';
            }).join('');
        }

        function renderGlobalHistory() {
            const container = document.getElementById('historyList');
            if (!container) return;

            const rows = Array.isArray(globalTxData) ? globalTxData.slice() : [];

            rows.sort(function(a, b) {
                return new Date(b.timestamp || b.date || 0) -
                    new Date(a.timestamp || a.date || 0);
            });

            if (!rows.length) {
                container.innerHTML = '<div class="empty-state">No transaction history.</div>';
                return;
            }

            container.innerHTML = rows.map(function(t) {
                const customer = t.customerName || t.customer || 'Unknown';
                const amount = Number(t.amount ?? t.total) || 0;
                const paid = Number(t.cashCollected ?? t.paid ?? t.payment) || 0;
                const balance = amount - paid;
                const date = t.timestamp || t.date || '';

                return '<div class="data-card">' +
                    '<div class="card-title">' + escapeHtml(customer) + '</div>' +
                    '<div class="muted">' + escapeHtml(String(date)) + '</div>' +
                    '<div class="card-grid">' +
                    '<div><small>Qty</small><strong>' + (Number(t.quantity) || 0) + '</strong></div>' +
                    '<div><small>Amount</small><strong>$' + amount.toFixed(2) + '</strong></div>' +
                    '<div><small>Paid</small><strong>$' + paid.toFixed(2) + '</strong></div>' +
                    '<div><small>Balance</small><strong>$' + balance.toFixed(2) + '</strong></div>' +
                    '</div>' +
                    (t.item ? '<div>' + escapeHtml(String(t.item)) + '</div>' : '') +
                    (t.notes ? '<div class="muted">' + escapeHtml(String(t.notes)) + '</div>' : '') +
                    '</div>';
            }).join('');
        }

        function renderPresetConfig() {
            const container = document.getElementById('presetConfig');
            if (!container) return;

            const presets = Array.isArray(appPresets) ? appPresets : [];

            container.innerHTML = presets.map(function(p, i) {
                return '<div class="preset-config-row">' +
                    '<input data-preset-label="' + i + '" value="' +
                    escapeHtml(p.label || '') + '">' +
                    '<input data-preset-amount="' + i + '" type="number" step="0.01" value="' +
                    Number(p.amount || 0).toFixed(2) + '">' +
                    '</div>';
            }).join('');
        }

        function savePresetsConfig() {
            const presets = Array.isArray(appPresets) ? appPresets : [];

            presets.forEach(function(p, i) {
                const label = document.querySelector('[data-preset-label="' + i + '"]');
                const amount = document.querySelector('[data-preset-amount="' + i + '"]');

                if (label) p.label = label.value;
                if (amount) p.amount = parseFloat(amount.value) || 0;
            });

            localStorage.setItem('salesTrackerPresets', JSON.stringify(presets));
            renderPresetButtons();
        }

        function exportData() {
            const payload = {
                customers: allCustomersData,
                transactions: globalTxData,
                exportedAt: new Date().toISOString()
            };

            const blob = new Blob(
                [JSON.stringify(payload, null, 2)],
                {type: 'application/json'}
            );

            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'sales-tracker-export-' +
                new Date().toISOString().slice(0, 10) + '.json';
            document.body.appendChild(a);
            a.click();
            a.remove();
            URL.revokeObjectURL(url);
        }

        async function importData(file) {
            if (!file) return;

            const text = await file.text();
            const payload = JSON.parse(text);

            const response = await fetch('/api/import', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify(payload)
            });

            if (!response.ok) {
                throw new Error('Import failed');
            }

            await loadData();
            switchTab('hist');
        }

        function filterProfiles() {
            renderProfilesList(allCustomersData);
        }

        function filterBalances() {
            renderBalancesList(allCustomersData);
        }

        function escapeHtml(value) {
            return String(value ?? '')
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;');
        }

        document.addEventListener('DOMContentLoaded', function() {
            try {
                const saved = localStorage.getItem('salesTrackerPresets');
                if (saved) {
                    const parsed = JSON.parse(saved);
                    if (Array.isArray(parsed)) appPresets = parsed;
                }
            } catch (e) {}

            loadData().catch(function(err) {
                console.error('Initial data load failed:', err);
            });

            renderPresetButtons();
        });
'''

def embed_client(prefix, client):
    # Only escape syntax that conflicts with the server's outer template literal.
    safe = client.replace('`', r'\`').replace('${', r'\${')
    return prefix + safe + '''
    </script>
    </body>
    </html>
    `);
    });

    app.listen(PORT, "0.0.0.0", () => {
        console.log("Server running on port " + PORT);
    });
'''

for version in ["v1", "v2", "v3", "v4", "v5"]:
    path = ROOT / version / "server.js"
    print("===", version, "===")

    if not path.exists():
        print("RED: missing", path)
        continue

    original = path.read_text()

    # Preserve a recovery copy before every mutation.
    backup = path.with_name("server.js.bak.pages-" + STAMP)
    shutil.copy2(path, backup)

    # Keep everything through the beginning of the HTML response.
    start = original.find("        function switchTab(tab) {")
    if start < 0:
        print("RED: switchTab marker not found")
        continue

    html_start = original.find('res.send(`<!DOCTYPE html>', 0)
    if html_start < 0:
        print("RED: outer HTML template marker not found")
        continue

    prefix = original[:start]

    # The existing server has its route declaration before the HTML.
    # We reconstruct the remainder, including the closing template and app.listen.
    rebuilt = embed_client(prefix, CLIENT)

    path.write_text(rebuilt)

    print("backup:", backup)
    print("bytes:", len(rebuilt))

