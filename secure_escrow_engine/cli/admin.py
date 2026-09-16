import sys
import json
import urllib.request

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 cli/admin.py {health|state|create}")
        sys.exit(1)

    cmd = sys.argv[1]
    base_url = "http://127.0.0.1:8080"

    if cmd == "health":
        req = urllib.request.Request(f"{base_url}/health")
        with urllib.request.urlopen(req) as resp:
            print(resp.read().decode())
    elif cmd == "state":
        req = urllib.request.Request(f"{base_url}/escrow/state")
        with urllib.request.urlopen(req) as resp:
            print(resp.read().decode())
    else:
        print(f"Unknown command: {cmd}")

if __name__ == "__main__":
    main()
