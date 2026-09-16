#!/usr/bin/env bash
set -e
ENDPOINT="http://127.0.0.1:8080"
echo "Testing /encrypt endpoint..."
ENCRYPT_RES=$(curl -s -X POST "$ENDPOINT/encrypt" \
    -H "Content-Type: application/json" \
    -d '{
        "key": "0123456789abcdef0123456789abcdef",
        "iv": "1234567890abcdef",
        "payload": "Automated pipeline payload"
    }')
echo "Encrypt Response: $ENCRYPT_RES"
CIPHERTEXT=$(echo "$ENCRYPT_RES" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)
if [ -z "$CIPHERTEXT" ]; then
    echo "Error: Encryption failed." >&2
    exit 1
fi
echo "Testing /decrypt endpoint..."
curl -s -X POST "$ENDPOINT/decrypt" \
    -H "Content-Type: application/json" \
    -d "{
        \"key\": \"0123456789abcdef0123456789abcdef\",
        \"iv\": \"1234567890abcdef\",
        \"payload\": \"$CIPHERTEXT\"
    }"
echo ""
