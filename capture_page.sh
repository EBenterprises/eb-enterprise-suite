#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Automated Page Capture & Archival Utility
# ==============================================================================
set -e

TARGET_URL=${1:-"http://localhost:5000"}
OUTPUT_DIR="./captures"
mkdir -p "$OUTPUT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CAPTURE_PATH="$OUTPUT_DIR/page_capture_$TIMESTAMP.html"

echo "[+] Initiating capture of target endpoint: $TARGET_URL"

if command -v curl &> /dev/null; then
    curl -s "$TARGET_URL" > "$CAPTURE_PATH"
    echo "[+] Page successfully captured via curl to: $CAPTURE_PATH"
elif command -v wget &> /dev/null; then
    wget -qO "$CAPTURE_PATH" "$TARGET_URL"
    echo "[+] Page successfully captured via wget to: $CAPTURE_PATH"
else
    echo "[!] Error: Neither curl nor wget is available on this system."
    exit 1
fi

echo "[+] Capture complete. File size: $(wc -c < "$CAPTURE_PATH") bytes."
