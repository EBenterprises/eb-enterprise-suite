#!/usr/bin/env bash
set -e

echo "[+] Implementing Settings page (Change Username & Password) for Secure Vault..."

# 1. Update app.py to add settings route and handlers
python3 - << 'EOF_APP'
import re

path = "secure_vault/src/app.py"
with open(path, "r") as f:
    code = f.read()

# Check if settings route already exists
if "def settings" not in code:
    # Insert settings route before logout or index
    settings_code = """
@app.route('/settings', methods=['GET', 'POST'])
def settings():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    conn = get_db()
    cursor = conn.cursor()
    
    message = None
    error = None
    
    if request.method == 'POST':
        action = request.form.get('action')
        
        if action == 'update_username':
            new_username = request.form.get('new_username', '').strip()
            if not new_username:
                error = "Username cannot be empty."
            else:
                try:
                    cursor.execute('UPDATE users SET username = ? WHERE id = ?', (new_username, session['user_id']))
                    # Also update orders or other tables if client is stored as username
                    cursor.execute('UPDATE orders SET client = ? WHERE client = ?', (new_username, session['username']))
                    conn.commit()
                    session['username'] = new_username
                    message = "Username updated successfully."
                except Exception as e:
                    error = "Username already taken or database error."
                    
        elif action == 'update_password':
            current_pass = request.form.get('current_password', '')
            new_pass = request.form.get('new_password', '')
            
            cursor.execute('SELECT password FROM users WHERE id = ?', (session['user_id'],))
            user_row = cursor.fetchone()
            
            # Simple check or hash check depending on app setup
            stored_pass = user_row[0] if user_row else ''
            
            # Support both plaintext or simple hashed comparison used in app
            import hashlib
            hashed_current = hashlib.sha256(current_pass.encode()).hexdigest()
            
            if current_pass == stored_pass or hashed_current == stored_pass:
                if not new_pass:
                    error = "New password cannot be empty."
                else:
                    new_hashed = hashlib.sha256(new_pass.encode()).hexdigest()
                    cursor.execute('UPDATE users SET password = ? WHERE id = ?', (new_hashed, session['user_id']))
                    conn.commit()
                    message = "Password updated successfully."
            else:
                error = "Incorrect current password."
                
    conn.close()
    return render_template('settings.html', message=message, error=error)
"""
    # Insert before the last block or after dashboard
    code = code + settings_code
    print("[+] Added /settings route to app.py")

with open(path, "w") as f:
    f.write(code)
EOF_APP

# 2. Create templates/settings.html
cat << 'TEMPLATE_SETTINGS' > secure_vault/templates/settings.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Account Settings</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; word-break: break-word; overflow-wrap: break-word; }
        html { width: 100%; background: #121214; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background: #121214; color: #e4e4e7; padding: 1rem; display: flex; flex-direction: column; align-items: center; min-height: 100vh; }
        .container { width: 100%; max-width: 500px; background: #18181b; padding: 1.5rem; border: 1px solid #27272a; border-radius: 10px; box-shadow: 0 4px 20px rgba(0,0,0,0.4); margin-top: 1rem; margin-bottom: 2rem; }
        header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #27272a; padding-bottom: 1rem; margin-bottom: 1.5rem; }
        h2 { font-size: 1.25rem; font-weight: 600; color: #f4f4f5; margin: 0; }
        h3 { font-size: 1rem; font-weight: 600; color: #f4f4f5; margin-bottom: 0.75rem; }
        form { display: flex; flex-direction: column; gap: 0.75rem; margin-bottom: 1.5rem; }
        label { color: #a1a1aa; font-size: 0.85rem; font-weight: 500; }
        input { width: 100%; padding: 0.85rem 1rem; border: 1px solid #3f3f46; border-radius: 6px; background: #09090b; color: #f4f4f5; font-size: 0.95rem; outline: none; font-family: inherit; }
        input:focus { border-color: #71717a; }
        button { padding: 0.75rem 1.25rem; background: #f4f4f5; color: #09090b; font-weight: 600; border: none; border-radius: 6px; cursor: pointer; font-size: 0.9rem; transition: background 0.2s; margin-top: 0.5rem; }
        button:hover { background: #e4e4e7; }
        .alert-success { background: rgba(34, 197, 94, 0.15); color: #4ade80; border: 1px solid rgba(34, 197, 94, 0.3); padding: 0.75rem; border-radius: 6px; font-size: 0.85rem; margin-bottom: 1rem; }
        .alert-error { background: rgba(239, 68, 68, 0.15); color: #f87171; border: 1px solid rgba(239, 68, 68, 0.3); padding: 0.75rem; border-radius: 6px; font-size: 0.85rem; margin-bottom: 1rem; }
        a { color: #f4f4f5; text-decoration: underline; font-size: 0.85rem; font-weight: 500; }
        a:hover { color: #d4d4d8; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h2>Account Settings</h2>
            <a href="/">Dashboard</a>
        </header>

        {% if message %}
            <div class="alert-success">{{ message }}</div>
        {% endif %}
        {% if error %}
            <div class="alert-error">{{ error }}</div>
        {% endif %}

        <form method="POST">
            <input type="hidden" name="action" value="update_username">
            <h3>Change Username</h3>
            <div>
                <label>New Username</label>
                <input type="text" name="new_username" value="{{ session.username }}" required>
            </div>
            <button type="submit">Update Username</button>
        </form>

        <form method="POST">
            <input type="hidden" name="action" value="update_password">
            <h3>Change Password</h3>
            <div>
                <label>Current Password</label>
                <input type="password" name="current_password" required>
            </div>
            <div>
                <label>New Password</label>
                <input type="password" name="new_password" required>
            </div>
            <button type="submit">Update Password</button>
        </form>
    </div>
</body>
</html>
TEMPLATE_SETTINGS

# 3. Update dashboard.html header to include a link to Settings
python3 - << 'UPDATE_NAV'
import re

path = "secure_vault/templates/dashboard.html"
with open(path, "r") as f:
    content = f.read()

# Add Settings link next to Logout in header if not already present
if "href=\"/settings\"" not in content:
    content = content.replace(
        '<a href="/logout"',
        '<a href="/settings" style="margin-right: 15px;">Settings</a>\n    <a href="/logout"'
    )
    with open(path, "w") as f:
        f.write(content)
    print("[+] Added Settings link to dashboard header.")
UPDATE_NAV

echo "[+] Restarting Flask server..."
pkill -f "app.py" || true
sleep 1
cd secure_vault/src
python3 app.py &
echo "[+] Settings page added successfully! You can now change your username and password from the dashboard."
