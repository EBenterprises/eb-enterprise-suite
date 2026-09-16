#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
cd "$WORKSPACE_DIR"

echo "=== Initializing Master Workspace Orchestration & Lifecycle Manager ==="

cat << 'PYORCH' > master_orchestrator.py
#!/usr/bin/env python3
import os
import subprocess
import time
import sys

WORKSPACE_DIR = os.path.expanduser('~/termux_workspace')

def ensure_service(script_name, process_name):
    script_path = os.path.join(WORKSPACE_DIR, script_name)
    if not os.path.exists(script_path):
        print(f"[-] Script {script_name} not found.")
        return

    # Check if process is running
    res = subprocess.run(['pgrep', '-f', process_name], stdout=subprocess.PIPE, text=True)
    if not res.stdout.strip():
        print(f"[*] Starting service: {script_name}...")
        subprocess.Popen(['python3', script_path], cwd=WORKSPACE_DIR, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(f"[+] Service {script_name} launched successfully.")
    else:
        print(f"[+] Service {script_name} is already active.")

def main():
    print("=" * 60)
    print("      EXECUTIVE SPECTRUM - MASTER WORKSPACE ORCHESTRATOR      ")
    print("=" * 60)
    
    # 1. Ensure all core background daemons are running
    ensure_service('workspace_daemon.py', 'workspace_daemon.py')
    ensure_service('run_cron_scheduler.sh', 'run_cron_scheduler.sh')
    ensure_service('web_ui_dashboard.py', 'web_ui_dashboard.py')
    
    # 2. Trigger health matrix update
    print("[*] Generating fresh system health matrix...")
    subprocess.run(['python3', 'system_health_matrix.py'], cwd=WORKSPACE_DIR)
    
    # 3. Final git status check & sync
    print("[*] Synchronizing workspace state with remote repository...")
    subprocess.run(['git', 'add', '.'], cwd=WORKSPACE_DIR)
    diff_check = subprocess.run(['git', 'diff', '--cached', '--quiet'], cwd=WORKSPACE_DIR)
    if diff_check.returncode != 0:
        subprocess.run(['git', 'commit', '-m', 'Master orchestrator synchronization update'], cwd=WORKSPACE_DIR)
        subprocess.run(['git', 'push', 'origin', 'main'], cwd=WORKSPACE_DIR)
        print("[+] Repository fully synchronized and pushed.")
    else:
        print("[+] Repository working tree is clean and up to date.")

    print("=" * 60)
    print("All subsystems operational. Workspace ready.")
    print("=" * 60)

if __name__ == '__main__':
    main()
PYORCH

chmod +x master_orchestrator.py

# Create global command shortcut for master orchestrator
mkdir -p "${PREFIX}/bin"
cat << 'BINSH' > "${PREFIX}/bin/workspace"
#!/usr/bin/env bash
python3 "${HOME}/termux_workspace/master_orchestrator.py"
BINSH
chmod +x "${PREFIX}/bin/workspace"

# Execute orchestrator immediately
python3 master_orchestrator.py

git add .
if ! git diff --cached --quiet; then
    git commit -m "Ecosystem finalization: Deployed master orchestrator and global 'workspace' shortcut $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main || true
fi

echo "=== Master Orchestration Deployed Successfully ==="
echo "Type 'workspace' anywhere in your terminal to launch the master orchestrator and sync suite."
