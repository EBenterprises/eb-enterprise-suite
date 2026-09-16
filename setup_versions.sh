#!/bin/bash
[ -d "secure_vault_local" ] || mkdir secure_vault_local
[ -d "secure_vault_onion" ] || mkdir secure_vault_onion
[ -d "secure_vault_public" ] || mkdir secure_vault_public

# Comprehensive fix for flask.jinja2 -> jinja2 references in app.py files
for dir in secure_vault_local secure_vault_onion secure_vault_public; do
    if [ -f "$dir/app.py" ]; then
        sed -i 's/flask\.jinja2/jinja2/g' "$dir/app.py"
        sed -i 's/import flask\.jinja2/import jinja2/g' "$dir/app.py"
    fi
done

# Create robust local runner
cat << 'INNER_LOCAL' > run_local.sh
#!/bin/bash
fuser -k 5000/tcp 2>/dev/null || pkill -f "python.*app.py" 2>/dev/null
cd secure_vault_local && python3 app.py
INNER_LOCAL
chmod +x run_local.sh

# Create robust onion runner
cat << 'INNER_ONION' > run_onion.sh
#!/bin/bash
fuser -k 5000/tcp 2>/dev/null || pkill -f "python.*app.py" 2>/dev/null
cd secure_vault_onion && python3 app.py
INNER_ONION
chmod +x run_onion.sh

# Create robust public runner with dynamic port detection
cat << 'INNER_PUBLIC' > run_public.sh
#!/bin/bash
echo "[+] Cleaning up existing processes..."
fuser -k 5000/tcp 2>/dev/null
fuser -k 5001/tcp 2>/dev/null
pkill -f "python.*app.py" 2>/dev/null

cd secure_vault_public
rm -f flask_run.log

python3 app.py > flask_run.log 2>&1 &
FLASK_PID=$!

echo "[+] Waiting for Flask to bind..."
PORT=""
for i in {1..10}; do
    if grep -q "Running on http://" flask_run.log 2>/dev/null; then
        PORT=$(grep -oE "http://[^[:space:]]+" flask_run.log | grep -oE "[0-9]+$" | head -n 1)
        break
    fi
    sleep 0.5
done

if [ -z "$PORT" ]; then
    PORT="5001"
fi

echo "[+] Flask detected running on port $PORT. Launching Cloudflare Tunnel..."
cloudflared tunnel --url http://localhost:$PORT &
TUNNEL_PID=$!

trap "kill $FLASK_PID $TUNNEL_PID 2>/dev/null; rm -f flask_run.log" EXIT
wait
INNER_PUBLIC
chmod +x run_public.sh

echo "[+] Patched and ready!"
