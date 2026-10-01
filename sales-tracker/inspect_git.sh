echo "=== Checking Git Status & History for Real Data ==="
git status
echo ""
git log -p -n 3 -- transactions.json profiles.json expenses.json || echo "No git history found for data files."
echo ""
echo "=== Checking all JSON files in directory ==="
ls -la *.json
