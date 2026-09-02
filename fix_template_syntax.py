import os
import glob

print("[+] Searching for templates with broken loops...")
for template_path in glob.glob("**/templates/**/*.html", recursive=True):
    with open(template_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Fix broken flash loops missing 'in get_flashed_messages...'
    updated = content.replace("{% for category, message %}", "{% for category, message in get_flashed_messages(with_categories=true) %}")
    
    if updated != content:
        with open(template_path, 'w', encoding='utf-8') as f:
            f.write(updated)
        print(f"[+] Fixed template syntax in: {template_path}")

print("[+] Template fix complete.")
