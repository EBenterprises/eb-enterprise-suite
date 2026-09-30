#!/bin/bash
set -euo pipefail

for v in v1 v2 v3 v4 v5; do
    file="instances/$v/server.js"

    echo "=== Restoring client application: $v ==="

    cp "$file" "$file.bak.client-$(date +%Y%m%d-%H%M%S)"

    python3 - "$file" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
s = path.read_text()

start = s.find("        function switchTab(tab) {")
if start == -1:
    raise SystemExit(f"switchTab() not found: {path}")

# Keep everything through the opening of switchTab().
prefix = s[:start]

client = r'''        function switchTab(tab) {
            const tabs = ['new', 'cust', 'bals', 'hist', 'sets'];

            tabs.forEach(t => {
                const name = t.charAt(0).toUpperCase() + t.slice(1);
                const tabEl = document.getElementById('tab' + name);
                const viewEl = document.getElementById('view' + name);

                if (tabEl) tabEl.classList.remove('active');
                if (viewEl) viewEl.classList.remove('active-view');
            });

            const name = tab.charAt(0).toUpperCase() + tab.slice(1);
            const activeTabEl = document.getElementById('tab' + name);
            const activeViewEl = document.getElementById('view' + name);

            if (activeTabEl) activeTabEl.classList.add('active');
            if (activeViewEl) activeViewEl.classList.add('active-view');

            if (tab === 'cust') {
                renderProfilesList(allCustomersData);
            } else if (tab === 'bals') {
                renderBalancesList(allCustomersData);
            } else if (tab === 'hist') {
                renderGlobalHistory();
            } else if (tab === 'sets') {
                renderPresetConfig();
            }
        }

        async function loadData() {
            const [customersResponse, transactionsResponse, settingsResponse] =
                await Promise.all([
                    fetch('/api/customers'),
                    fetch('/api/transactions'),
                    fetch('/api/settings')
                ]);

            if (!customersResponse.ok ||
                !transactionsResponse.ok ||
                !settingsResponse.ok) {
                throw new Error('Failed to load application data');
            }

            allCustomersData = await customersResponse.json();
            globalTxData = await transactionsResponse.json();

            const settings = await settingsResponse.json();

            if (Array.isArray(settings.presets)) {
                appPresets = settings.presets;
            }

            renderPresetButtons();
            populateCustomerOptions();

            if (document.getElementById('viewCust').classList.contains('active-view')) {
                renderProfilesList(allCustomersData);
            }

            if (document.getElementById('viewBals').classList.contains('active-view')) {
                renderBalancesList(allCustomersData);
            }

            if (document.getElementById('viewHist').classList.contains('active-view')) {
                renderGlobalHistory();
            }

            if (document.getElementById('viewSets').classList.contains('active-view')) {
                renderPresetConfig();
            }
        }

        function populateCustomerOptions() {
            const list = document.getElementById('customerListOptions');
            if (!list) return;

            list.innerHTML = '';

            allCustomersData.forEach(customer => {
                const option = document.createElement('option');
                option.value = customer.customer;
                list.appendChild(option);
            });
        }

        function renderPresetButtons() {
            const container = document.getElementById('presetButtonsGrid');
            if (!container) return;

            container.innerHTML = '';

            appPresets.forEach(preset => {
                const button = document.createElement('button');

                button.type = 'button';
                button.className = 'preset-btn';
                button.textContent =
                    `${Number(preset.weight).toFixed(2).replace(/\.00$/, '')}g $${Number(preset.price).toFixed(2)}`;

                button.onclick = () => {
                    document.getElementById('weightInput').value = preset.weight;
                    document.getElementById('amountInput').value = preset.price;
                    calculate();
                };

                container.appendChild(button);
            });
        }

        function calculate() {
            const weight = parseFloat(document.getElementById('weightInput').value) || 0;
            const amount = parseFloat(document.getElementById('amountInput').value) || 0;
            const cash = parseFloat(document.getElementById('cashInput').value) || 0;

            const balance = Math.max(0, amount - cash);

            const summary = document.getElementById('outputSummary');
            const outputBal = document.getElementById('outputBal');

            if (summary) {
                summary.textContent =
                    weight > 0 || amount > 0
                        ? `${weight}g — $${amount.toFixed(2)}`
                        : 'Select preset or enter weight';
            }

            if (outputBal) {
                outputBal.textContent = `New Bal: $${balance.toFixed(2)}`;
            }
        }

        function setCash(amount) {
            const cashInput = document.getElementById('cashInput');
            if (!cashInput) return;

            cashInput.value = amount;
            calculate();
        }

        function setCashExact() {
            const amount = parseFloat(document.getElementById('amountInput').value) || 0;
            setCash(amount);
        }

        function onCustomerInput(value) {
            const customer = allCustomersData.find(
                c => c.customer.toLowerCase() === value.trim().toLowerCase()
            );

            const notice = document.getElementById('existingBalNotice');

            if (!notice) return;

            if (customer && Number(customer.currentBalance) > 0) {
                notice.style.display = 'block';
                notice.textContent =
                    `Existing balance: $${Number(customer.currentBalance).toFixed(2)}`;
            } else {
                notice.style.display = 'none';
                notice.textContent = '';
            }
        }

        async function recordTransaction() {
            const customer =
                document.getElementById('customerInput').value.trim() || 'Guest';

            const weight =
                parseFloat(document.getElementById('weightInput').value) || 0;

            const amount =
                parseFloat(document.getElementById('amountInput').value) || 0;

            const cashCollected =
                parseFloat(document.getElementById('cashInput').value) || 0;

            const location =
                document.getElementById('locationInput').value.trim() || currentGPS;

            if (amount <= 0) {
                alert('Enter an amount before recording the sale.');
                return;
            }

            try {
                const response = await fetch('/api/transactions', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        customer,
                        gps: location,
                        item: weight > 0 ? `${weight}g` : 'Custom Unit',
                        amount,
                        cashCollected
                    })
                });

                const result = await response.json();

                if (!response.ok || !result.success) {
                    throw new Error(result.error || 'Transaction failed');
                }

                document.getElementById('weightInput').value = '';
                document.getElementById('amountInput').value = '';
                document.getElementById('cashInput').value = '0';

                await loadData();

                alert('Sale recorded successfully.');
            } catch (error) {
                console.error(error);
                alert('Failed to record sale: ' + error.message);
            }
        }

        function renderProfilesList(data) {
            const container = document.getElementById('profilesList');
            if (!container) return;

            const query =
                (document.getElementById('searchProfileInput')?.value || '')
                    .trim()
                    .toLowerCase();

            const filtered = data.filter(c =>
                !query ||
                c.customer.toLowerCase().includes(query) ||
                (c.phone || '').toLowerCase().includes(query) ||
                (c.notes || '').toLowerCase().includes(query)
            );

            if (!filtered.length) {
                container.innerHTML = '<div style="padding:10px;">No profiles found.</div>';
                return;
            }

            container.innerHTML = filtered.map(c => `
                <div class="ledger-item" style="display:block;">
                    <strong>${escapeHtml(c.customer)}</strong>
                    <div style="color:#94a3b8;">
                        ${escapeHtml(c.phone || 'No phone')}
                    </div>
                    <div style="color:#94a3b8;">
                        ${escapeHtml(c.notes || '')}
                    </div>
                    <div>
                        Purchased: $${Number(c.totalPurchased || 0).toFixed(2)}
                        &nbsp;|&nbsp;
                        Paid: $${Number(c.totalPaid || 0).toFixed(2)}
                        &nbsp;|&nbsp;
                        Balance: $${Number(c.currentBalance || 0).toFixed(2)}
                    </div>
                </div>
            `).join('');
        }

        function renderBalancesList(data) {
            const container = document.getElementById('balancesList');
            if (!container) return;

            const query =
                (document.getElementById('searchBalsInput')?.value || '')
                    .trim()
                    .toLowerCase();

            const filtered = data.filter(c =>
                Number(c.currentBalance || 0) > 0 &&
                (!query || c.customer.toLowerCase().includes(query))
            );

            if (!filtered.length) {
                container.innerHTML =
                    '<div style="padding:10px;">No outstanding balances.</div>';
                return;
            }

            container.innerHTML = filtered.map(c => `
                <div class="ledger-item">
                    <span>
                        <strong>${escapeHtml(c.customer)}</strong><br>
                        <small>Paid: $${Number(c.totalPaid || 0).toFixed(2)}</small>
                    </span>
                    <strong style="color:#fbbf24;">
                        $${Number(c.currentBalance || 0).toFixed(2)}
                    </strong>
                </div>
            `).join('');
        }

        function renderGlobalHistory() {
            const container = document.getElementById('globalLedgerList');
            if (!container) return;

            if (!globalTxData.length) {
                container.innerHTML =
                    '<div style="padding:10px;">No transactions recorded.</div>';
                return;
            }

            container.innerHTML = globalTxData.map(tx => `
                <div class="ledger-item" style="display:block;">
                    <div style="display:flex;justify-content:space-between;gap:8px;">
                        <strong>${escapeHtml(tx.customer || 'Guest')}</strong>
                        <strong>$${Number(tx.amount || 0).toFixed(2)}</strong>
                    </div>
                    <div style="color:#94a3b8;">
                        ${escapeHtml(tx.date || '')}
                        &nbsp;|&nbsp;
                        ${escapeHtml(tx.item || '')}
                    </div>
                    <div>
                        Paid: $${Number(tx.cashCollected || 0).toFixed(2)}
                        &nbsp;|&nbsp;
                        Balance: $${Number(tx.balance || 0).toFixed(2)}
                        &nbsp;|&nbsp;
                        ${escapeHtml(tx.status || '')}
                    </div>
                    <div style="color:#64748b;">
                        ${escapeHtml(tx.gps || '')}
                    </div>
                </div>
            `).join('');
        }

        function renderPresetConfig() {
            const container = document.getElementById('presetConfigList');
            if (!container) return;

            container.innerHTML = appPresets.map((preset, index) => `
                <div class="row" style="margin-bottom:6px;">
                    <div>
                        <label>Weight (g)</label>
                        <input
                            type="number"
                            step="0.01"
                            data-preset-weight="${index}"
                            value="${Number(preset.weight)}"
                        >
                    </div>
                    <div>
                        <label>Price ($)</label>
                        <input
                            type="number"
                            step="0.01"
                            data-preset-price="${index}"
                            value="${Number(preset.price)}"
                        >
                    </div>
                </div>
            `).join('');
        }

        async function savePresetsConfig() {
            const inputs = document.querySelectorAll('[data-preset-weight]');
            const presets = [];

            inputs.forEach(input => {
                const index = Number(input.dataset.presetWeight);
                const priceInput =
                    document.querySelector(`[data-preset-price="${index}"]`);

                const weight = parseFloat(input.value);
                const price = parseFloat(priceInput?.value);

                if (Number.isFinite(weight) && Number.isFinite(price)) {
                    presets.push({ weight, price });
                }
            });

            try {
                const response = await fetch('/api/settings', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ presets })
                });

                const result = await response.json();

                if (!response.ok || !result.success) {
                    throw new Error(result.error || 'Save failed');
                }

                appPresets = presets;
                renderPresetButtons();
                renderPresetConfig();

                alert('Preset configuration saved.');
            } catch (error) {
                console.error(error);
                alert('Failed to save presets: ' + error.message);
            }
        }

        async function exportData() {
            try {
                const response = await fetch('/api/export');

                if (!response.ok) {
                    throw new Error('Export failed');
                }

                const blob = await response.blob();
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');

                a.href = url;
                a.download = 'ledger_backup.json';
                document.body.appendChild(a);
                a.click();
                a.remove();

                URL.revokeObjectURL(url);
            } catch (error) {
                console.error(error);
                alert('Export failed: ' + error.message);
            }
        }

        async function importData(event) {
            const file = event.target.files?.[0];
            if (!file) return;

            try {
                const text = await file.text();
                const backup = JSON.parse(text);

                const response = await fetch('/api/import', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(backup)
                });

                const result = await response.json();

                if (!response.ok || !result.success) {
                    throw new Error(result.error || 'Import failed');
                }

                await loadData();

                alert('Backup imported successfully.');
            } catch (error) {
                console.error(error);
                alert('Import failed: ' + error.message);
            } finally {
                event.target.value = '';
            }
        }

        function filterProfiles(value) {
            renderProfilesList(allCustomersData);
        }

        function filterBalances(value) {
            renderBalancesList(allCustomersData);
        }

        function escapeHtml(value) {
            return String(value ?? '')
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#039;');
        }

        loadData().catch(err => {
            console.error('Failed to load application data:', err);
        });
    </script>
    </body>
    </html>
    `);

    app.listen(PORT, "0.0.0.0", () => {
        console.log("Server running on port " + PORT);
    });
'''

path.write_text(prefix + client)
PY

    node --check "$file"
    echo "[PASS] $v"
done

echo
echo "=== VERIFY REQUIRED FUNCTIONS ==="
for v in v1 v2 v3 v4 v5; do
    file="instances/$v/server.js"
    echo "--- $v ---"
    grep -q 'function loadData' "$file" && echo "loadData PASS"
    grep -q 'function renderProfilesList' "$file" && echo "Profiles PASS"
    grep -q 'function renderBalancesList' "$file" && echo "Balances PASS"
    grep -q 'function renderGlobalHistory' "$file" && echo "History PASS"
    grep -q 'function renderPresetConfig' "$file" && echo "Settings PASS"
    grep -q 'function recordTransaction' "$file" && echo "Sale PASS"
done

echo
echo "[+] Client pages restored."
