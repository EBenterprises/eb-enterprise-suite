#!/usr/bin/env bash
set -e

echo "[+] Inspecting app.py to verify /settings route and templates..."

python3 - << 'EOF_INSPECT'
import os

app_path = "secure_vault/src/app.py"
if os.path.exists(app_path):
    with open(app_path, "r") as f:
        code = f.read()
    print(f"[+] app.py exists. Length: {len(code)} bytes.")
    if "/settings" in code:
        print("[+] Route '/settings' is present in app.py.")
    else:
        print("[!] Route '/settings' is MISSING in app.py!")
else:
    print("[!] secure_vault/src/app.py not found!")

settings_path = "secure_vault/templates/settings.html"
if os.path.exists(settings_path):
    print("[+] settings.html template exists.")
else:
    print("[!] settings.html template is MISSING!")
EOF_INSPECT

# Let's cleanly inject the settings route directly into app.py right above `if __name__ == '__main__':` or at the end
python3 - << 'EOF_FIX'
path = "secure_vault/src/app.py"
with open(path, "r") as f:
    code = f.read()

# Remove any broken or duplicate settings routes first
if "def settings():" in code:
    # Let's strip out existing settings route to avoid duplication errors
    parts = code.split("@app.route('/settings', methods=['GET', 'POST'])")
    code = parts[0]

settings_block = """
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
                    cursor.execute('UPDATE orders SET client = ? WHERE client = ?', (new_username, session['username']))
                    conn.commit()
                    session['username'] = new_username
                    message = "Username updated successfully."
                except Exception as e:
                    error = f"Error updating username: {e}"
                    
        elif action == 'update_password':
            current_pass = request.form.get('current_password', '')
            new_pass = request.form.get('new_password', '')
            
            cursor.execute('SELECT password FROM users WHERE id = ?', (session['user_id'],))
            row = cursor.fetchone()
            
            if row:
                stored_pass = row[0]
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
            else:
                error = "User not found."
                
    conn.close()
    return render_template('settings.html', message=message, error=error)
"""

# Append before main block
if "if __name__ == '__main__':" in code:
    code = code.replace("if __name__ == '__main__':", settings_block + "\n\nif __name__ == '__main__':")
else:
    code += settings_block

with open(path, "w") as f:
    f.write(code)

print("[+] Successfully re-injected /settings route cleanly into app.py.")
EOF_FIX

echo "[+] Restarting Flask server..."
pkill -f "app.py" || true
sleep 1
cd secure_vault/src
python3 app.py &
echo "[+] Done! Check http://localhost:5000/settings or click the Settings link on your dashboard."
