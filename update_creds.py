import sys

new_user = input("Enter desired Access Identifier: ").strip()
new_pass = input("Enter desired Decryption Key: ").strip()

app_path = "src/app.py"
with open(app_path, "r") as f:
    content = f.read()

# Replace the credential check block
import re
target_pattern = r'if username == ".*?" and password == ".*?":'
replacement = f'if username == "{new_user}" and password == "{new_pass}":'

new_content, count = re.subn(target_pattern, replacement, content)

if count > 0:
    with open(app_path, "w") as f:
        f.write(new_content)
    print(f"[+] Credentials updated successfully! Use User: '{new_user}' / Pass: '{new_pass}'")
else:
    print("[!] Could not locate credential check pattern in src/app.py.")
