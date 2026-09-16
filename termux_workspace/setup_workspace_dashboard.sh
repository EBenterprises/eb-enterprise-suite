#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
DASHBOARD_SCRIPT="${WORKSPACE_DIR}/workspace_status.py"

cat << 'INNER_EOF' > "$DASHBOARD_SCRIPT"
#!/usr/bin/env python3
import os
import subprocess
import glob
from datetime import datetime

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")

def run_cmd(cmd):
    try:
        res = subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return res.stdout.strip()
    except subprocess.CalledProcessError:
        return "N/A"

def main():
    os.chdir(WORKSPACE_DIR)
    
    print("=" * 60)
    print(f"  TERMUX WORKSPACE EXECUTIVE DASHBOARD")
    print(f"  Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    
    git_status = run_cmd("git status --short")
    git_branch = run_cmd("git branch --show-current")
    git_remote = run_cmd("git remote get-url origin")
    
    print(f"\n[+] Git Repository:")
    print(f"    Branch: {git_branch}")
    print(f"    Remote: {git_remote}")
    print(f"    Status: {'Clean' if not git_status else 'Uncommitted Changes'}")
    if git_status:
        for line in git_status.splitlines():
            print(f"      {line}")
            
    snippets_count = len(glob.glob(os.path.join(WORKSPACE_DIR, "snippets", "*.txt")))
    print(f"\n[+] Snippets Stored: {snippets_count}")
    
    daemons = ["workspace_status.sh", "clip_daemon.sh", "run_cron_scheduler.sh"]
    print(f"\n[+] Active Background Daemons:")
    for daemon in daemons:
        pid = run_cmd(f"pgrep -f {daemon}")
        status = f"Running (PID: {pid})" if pid != "N/A" else "Stopped"
        print(f"    - {daemon}: {status}")
        
    print("\n" + "=" * 60)

if __name__ == "__main__":
    main()
INNER_EOF

chmod +x "$DASHBOARD_SCRIPT"

cat << 'INNER_EOF' > "${PREFIX}/bin/workspace"
#!/usr/bin/env bash
python3 "${HOME}/termux_workspace/workspace_status.sh"
INNER_EOF

chmod +x "${PREFIX}/bin/workspace"

echo "Workspace dashboard script created and aliased to 'workspace'."
python3 "$DASHBOARD_SCRIPT"
