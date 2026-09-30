#!/bin/bash
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")

for v in "${VERSIONS[@]}"; do
    file="instances/$v/server.js"
    if [ -f "$file" ]; then
        echo "Performing precise structural fix on $file..."
        python3 -c '
path = "'$file'"
with open(path, "r") as f:
    content = f.read()

# Strip everything from app.listen or switchTab closing onwards
idx = content.find("function switchTab")
if idx == -1:
    idx = content.find("app.listen")

if idx != -1:
    # Let us keep everything up to the start of switchTab or clean it up
    pass

# Instead of partial strip, let us find where loadData begins its messy tail and replace from there
tail_anchor = "loadData().then(() => {"
idx_tail = content.rfind(tail_anchor)
if idx_tail != -1:
    content = content[:idx_tail]

footer = """loadData().then(() => {
    if (tab === \"cust\") renderProfilesList(allCustomersData);
    else if (tab === \"bals\") renderBalancesList(allCustomersData);
    else if (tab === \"hist\") renderGlobalHistory();
    else if (tab === \"sets\") renderPresetConfig();
}).catch(err => {
    console.error(\"Failed to load data for tab:\", err);
});
}

app.listen(PORT, \"0.0.0.0\", () => {
    console.log(\"Server running on port \" + PORT);
});
</script>
</body>
</html>
"""

with open(path, "w") as f:
    f.write(content.strip() + "\n\n" + footer)
'
        node --check "$file" && echo "  -> $file syntax OK!"
    fi
done

echo "[+] Precise structural fix applied!"
