const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Let's inspect what happens inside the save-edit-btn click handler. If it's missing `e.preventDefault()` or `e.stopPropagation()`, or if the fetch call fails or throws a JS error, it stops execution.
// Let's replace the entire save-edit-btn loop with robust error-caught logging and direct fetch execution.

const robustSaveEditHandler = `
    document.querySelectorAll('.save-edit-btn').forEach(btn => {
        btn.onclick = async function(e) {
            if (e) e.preventDefault();
            const id = this.getAttribute('data-id');
            const custEl = document.getElementById('edit_cust_' + id);
            const landEl = document.getElementById('edit_land_' + id);
            const gpsEl = document.getElementById('edit_gps_' + id);
            const amtEl = document.getElementById('edit_amt_' + id);
            const cashEl = document.getElementById('edit_cash_' + id);
            const tsEl = document.getElementById('edit_ts_' + id);

            const payload = {
                id: id,
                customer: custEl ? custEl.value.trim() : '',
                landmark: landEl ? landEl.value.trim() : '',
                gps: gpsEl ? gpsEl.value.trim() : '',
                amount: amtEl ? Number(amtEl.value) || 0 : 0,
                cashCollected: cashEl ? Number(cashEl.value) || 0 : 0,
                customTimestamp: tsEl ? tsEl.value : null
            };

            try {
                const res = await fetch('/api/action', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ action: 'update_tx', payload })
                });
                const json = await res.json();
                if (json.success) {
                    alert('Transaction updated successfully!');
                    if (typeof loadData === 'function') loadData();
                    else location.reload();
                } else {
                    alert('Failed to update: ' + (json.error || 'Unknown error'));
                }
            } catch (err) {
                console.error(err);
                alert('Network error updating transaction.');
            }
        };
    });
`;

// Replace existing save-edit-btn binding block
code = code.replace(
    /document\.querySelectorAll\('\.save-edit-btn'\)\.forEach\(btn\s*=>\s*\{[^}]+\}\);\s*\});?/s,
    robustSaveEditHandler
);

// Also check the main "Save" button for new transactions (if "hit go" refers to the main Sale submission button)
const robustMainSaveHandler = `
    const saveBtn = document.getElementById('saveBtn');
    if (saveBtn) {
        saveBtn.onclick = async function(e) {
            if (e) e.preventDefault();
            const custEl = document.getElementById('custInput');
            const amtEl = document.getElementById('amountInput');
            const cashEl = document.getElementById('cashInput');
            const landEl = document.getElementById('landmarkInput');
            const gpsEl = document.getElementById('gpsInput');
            const tsEl = document.getElementById('saleTimestampInput');

            const payload = {
                customer: custEl ? custEl.value.trim() : '',
                amount: amtEl ? Number(amtEl.value) || 0 : 0,
                cashCollected: cashEl ? Number(cashEl.value) || 0 : 0,
                landmark: landEl ? landEl.value.trim() : '',
                gps: gpsEl ? gpsEl.value.trim() : '',
                customTimestamp: tsEl ? tsEl.value : null
            };

            try {
                const res = await fetch('/api/action', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ action: 'add_tx', payload })
                });
                const json = await res.json();
                if (json.success) {
                    alert('Transaction saved!');
                    if (typeof loadData === 'function') loadData();
                    else location.reload();
                } else {
                    alert('Failed to save.');
                }
            } catch (err) {
                console.error(err);
                alert('Network error saving transaction.');
            }
        };
    }
`;

// Replace main save button handler if present
if (code.includes("document.getElementById('saveBtn')")) {
    code = code.replace(
        /document\.getElementById\('saveBtn'\)\.onclick\s*=\s*async\s*function\(\)\s*\{[^}]+\};/s,
        robustMainSaveHandler
    );
}

fs.writeFileSync(serverPath, code);
console.log("[+] All click handlers updated with robust event handling and alerts.");
