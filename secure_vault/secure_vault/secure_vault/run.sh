#!/bin/bash
fuser -k 5000/tcp 2>/dev/null || pkill -f "python.*app.py" 2>/dev/null
cd app && python3 app.py &
sleep 1
cloudflared tunnel --url http://localhost:5000
