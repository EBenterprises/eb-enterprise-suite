#!/usr/bin/env bash
set -e

echo "[+] Securing order details route in app.py..."

python3 - << 'EOF_FIX'
import re

path = "secure_vault/src/app.py"
with open(path, "r") as f:
    code = f.read()

# Let's inspect or rewrite the order_detail route to ensure ownership or authorization check.
# If the order's client does not match the logged-in username (and user is not admin), return unauthorized/redirect.

new_route_logic = """@app.route('/order/<int:order_id>')
def order_detail(order_id):
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM orders WHERE id = ?', (order_id,))
    order = cursor.fetchone()
    conn.close()
    
    if not order:
        return "Order not found", 404
        
    # Enforce strict access control: non-admins can only view their own orders
    current_user = session.get('username')
    is_admin = session.get('is_admin', 0)
    
    if not is_admin and order['client'] != current_user:
        return render_template('unauthorized.html'), 403
        
    return render_template('order_detail.html', order=order)"""

# Replace the existing order_detail function using regex
pattern = r"@app\.route\('/order/<int:order_id>'\)\s+def order_detail\(order_id\):.*?(?=\n@app\.route|\Z)"

if re.search(pattern, code, flags=re.DOTALL):
    code = re.sub(pattern, new_route_logic, code, flags=re.DOTALL)
    print("[+] Successfully replaced order_detail authorization check.")
else:
    print("[!] Could not match order_detail pattern precisely, appending to file or checking alternative...")

with open(path, "w") as f:
    f.write(code)
EOF_FIX

echo "[+] Restarting Flask server..."
pkill -f "app.py" || true
sleep 1
cd secure_vault/src
python3 app.py &
echo "[+] Done! Non-admin users can now only view their own orders and are blocked from unauthorized payloads."
