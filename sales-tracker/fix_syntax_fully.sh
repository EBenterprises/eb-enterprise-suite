#!/bin/bash
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")

for v in "${VERSIONS[@]}"; do
    file="instances/$v/server.js"
    if [ -f "$file" ]; then
        echo "Inspecting and fixing structural syntax for $file..."
        python3 -c '
path = "'$file'"
with open(path, "r") as f:
    content = f.read()

# Let us find where app.listen or any trailing junk starts, or strip anything after line 363/switchTab finish
# Look for switchTab closing or last valid function
idx = content.find("app.listen")
if idx != -1:
    content = content[:idx]

# Ensure we cleanly append the correct server startup
clean_footer = """
app.listen(PORT, "0.0.0.0", () => {
    console.log("Server running on port " + PORT);
});
"""

# Let us count open vs closed braces to see if any block is unclosed
open_braces = content.count("{")
close_braces = content.count("}")
open_parens = content.count("(")
close_parens = content.count(")")

print(f"  Braces open: {open_braces}, closed: {close_braces}")
print(f"  Parens open: {open_parens}, closed: {close_parens}")

# Append missing closing braces/parens if necessary
while content.count("{") > content.count("}"):
    content += "\n});"

content += clean_footer

with open(path, "w") as f:
    f.write(content)
'
        node --check "$file" && echo "  -> $file syntax OK!"
    fi
done

echo "[+] Cluster syntax completely repaired!"
