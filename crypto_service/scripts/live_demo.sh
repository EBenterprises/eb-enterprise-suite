#!/usr/bin/env bash
set -e

PORT="${PORT:-8080}"
BASE_URL="http://127.0.0.1:$PORT"

echo "=== 1. Checking Web UI Console Dashboard ==="
curl -s "$BASE_URL/" | head -n 15

echo -e "\n\n=== 2. Testing /encrypt Endpoint ==="
ENC_RESPONSE=$(curl -s -X POST "$BASE_URL/encrypt" \
  -H "Content-Type: application/json" \
  -d '{
    "key": "0123456789abcdef0123456789abcdef",
    "iv": "abcdef9876543210",
    "payload": "Modular monolith live action demo"
  }')
echo "$ENC_RESPONSE"

CIPHERTEXT=$(echo "$ENC_RESPONSE" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

echo -e "\n=== 3. Testing /decrypt Endpoint ==="
curl -s -X POST "$BASE_URL/decrypt" \
  -H "Content-Type: application/json" \
  -d "{
    \"key\": \"0123456789abcdef0123456789abcdef\",
    \"iv\": \"abcdef9876543210\",
    \"payload\": \"$CIPHERTEXT\"
  }"
echo -e "\n\n=== Live Demo Sequence Completed Successfully ==="
