#!/bin/bash
set -e
echo "=========================================================="
echo " EB Enterprises - Sales Tracker Production Ready"
echo "=========================================================="
echo " Directory: $(pwd)"
echo " Server Process: $(pgrep -f "node server.js" && echo "Active (PID $(pgrep -f "node server.js"))" || echo "Inactive")"
echo " Live Endpoint: http://localhost:3000"
echo " Management Commands:"
echo "   ./run.sh     - Start/Restart Node Server"
echo "   ./status.sh  - Check system & health"
echo "   ./deploy.sh  - Package tar.gz deployment archive"
echo "=========================================================="
