#!/data/data/com.termux/files/usr/bin/bash
set -u

RAM_MB="$(awk '/MemAvailable/ {printf "%d",$2/1024; exit}' /proc/meminfo 2>/dev/null || echo 0)"

if [ "$RAM_MB" -lt 256 ]; then
    echo "CRITICAL"
    exit 3
elif [ "$RAM_MB" -lt 512 ]; then
    echo "LOW"
    exit 2
elif [ "$RAM_MB" -lt 1024 ]; then
    echo "CONSTRAINED"
    exit 1
else
    echo "HEALTHY"
    exit 0
fi
