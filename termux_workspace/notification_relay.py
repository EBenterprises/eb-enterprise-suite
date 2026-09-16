#!/usr/bin/env python3
import os
import sys
import json
import urllib.request
import datetime

WORKSPACE_DIR = os.path.expanduser('~/termux_workspace')
LOG_PATH = os.path.join(WORKSPACE_DIR, 'notification_relay.log')

def log_notification(level, message):
    timestamp = datetime.datetime.now().isoformat()
    entry = f"[{timestamp}] [{level.upper()}] {message}\n"
    print(entry.strip())
    with open(LOG_PATH, 'a') as f:
        f.write(entry)

def notify(level, message):
    log_notification(level, message)
    # Optional webhook integration placeholder if webhook URL env var is set
    webhook_url = os.environ.get('WORKSPACE_WEBHOOK_URL')
    if webhook_url:
        try:
            payload = json.dumps({"level": level, "message": message, "timestamp": datetime.datetime.now().isoformat()}).encode('utf-8')
            req = urllib.request.Request(webhook_url, data=payload, headers={'Content-Type': 'application/json'})
            urllib.request.urlopen(req, timeout=5)
        except Exception as e:
            log_notification("ERROR", f"Failed to dispatch webhook: {e}")

if __name__ == '__main__':
    if len(sys.argv) >= 3:
        notify(sys.argv[1], sys.argv[2])
    else:
        print("Usage: python3 notification_relay.py <level> <message>")
