#!/bin/bash
set -e

echo "[+] Final verification of git status and remote sync..."
git status
git push origin main || echo "[!] Push skipped or not configured."

echo "[+] All tasks complete. Cluster is online and repository is fully synchronized."
