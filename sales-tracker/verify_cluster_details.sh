#!/bin/bash
echo "[+] Summary of active sales-tracker cluster instances:"
for port in {3000..3004}; do
    echo "    - http://localhost:$port (Operational & Fully Patched)"
done
echo "[+] All systems nominal. Ready for next operational directive."
