echo "=== Checking contents of data.json ==="
cat data.json
echo ""
echo "=== Checking git log for data.json ==="
git log -p -n 5 -- data.json || echo "No git history for data.json"
