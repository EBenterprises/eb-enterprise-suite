#!/usr/bin/env bash
echo "=== Inspecting ports for active Node PIDs ==="
for pid in 4689 4690 4691 4692 4698; do
    if [ -d "/proc/$pid" ]; then
        echo "PID $pid is running. Checking command line and open files/sockets..."
        cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' '
        echo ""
    fi
done

echo "=== Quick TCP Port Scan (3000-3105) ==="
for p in $(seq 3000 3105); do
    if nc -z 127.0.0.1 "$p" 2>/dev/null; then
        echo "--> Port $p is OPEN and listening!"
    fi
done
