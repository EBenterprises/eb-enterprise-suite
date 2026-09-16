#!/usr/bin/env bash
LAST_CLIP=""
while true; do
    if command -v termux-clipboard-get &> /dev/null; then
        CURRENT_CLIP=$(termux-clipboard-get 2>/dev/null || true)
        if [ -n "$CURRENT_CLIP" ] && [ "$CURRENT_CLIP" != "$LAST_CLIP" ]; then
            LAST_CLIP="$CURRENT_CLIP"
            echo "$CURRENT_CLIP" | gpaste >/dev/null 2>&1 || true
        fi
    fi
    sleep 10
done
