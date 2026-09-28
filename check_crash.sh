#!/usr/bin/env bash
echo "=== Kernel OOM Log Entries ==="
dmesg | grep -i -E "oom|killed|python3" | tail -n 10

echo -e "\n=== Application Log Output ==="
cat logs/vault_runtime.log
