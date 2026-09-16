#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - CSS Linking & Static Asset Fix
# ==============================================================================
set -e

# Ensure index.html includes the stylesheet correctly
if [ -f "index.html" ]; then
    node -e '
        const fs = require("fs");
        let html = fs.readFileSync("index.html", "utf8");
        if (!html.includes("style.css")) {
            html = html.replace(
                /<\/head>/,
                "    <link rel=\"stylesheet\" href=\"style.css\">\n</head>"
            );
            fs.writeFileSync("index.html", html, "utf8");
            console.log("    -> Injected <link rel=\"stylesheet\" href=\"style.css\"> into index.html");
        }
    '
fi

# Ensure all instances also have the public/style.css file copied over
for d in instances/v*; do
    if [ -d "$d" ]; then
        mkdir -p "$d/public"
        cp -f public/style.css "$d/public/style.css"
        cp -f public/style.css "$d/style.css" 2>/dev/null || true
        
        # Patch instance index.html if it exists
        if [ -f "$d/public/index.html" ]; then
            node -e '
                const fs = require("fs");
                let html = fs.readFileSync("' "$d/public/index.html" '", "utf8");
                if (!html.includes("style.css")) {
                    html = html.replace(/<\/head>/, "    <link rel=\"stylesheet\" href=\"style.css\">\n</head>");
                    fs.writeFileSync("' "$d/public/index.html" '", html, "utf8");
                }
            ' 2>/dev/null || true
        fi
    fi
done

echo "[+] CSS linking deployment complete."
