#!/data/data/com.termux/files/usr/bin/bash
set -u

clear

echo "=============================================================="
echo " COMPLETION ENGINE® — SELF-BOOTSTRAP REPAIR"
echo "=============================================================="

PASS=0
FAIL=0

ok() {
    echo "✓ $1"
    PASS=$((PASS+1))
}

bad() {
    echo "✗ $1"
    FAIL=$((FAIL+1))
}

echo
echo "[1] PACKAGE MANAGER"
echo "--------------------------------------------------------------"

if command -v pkg >/dev/null 2>&1; then
    ok "Termux package manager available"
else
    bad "Termux package manager unavailable"
    exit 1
fi

echo
echo "[2] GIT"
echo "--------------------------------------------------------------"

if command -v git >/dev/null 2>&1; then
    ok "Git already available"
else
    echo "Installing Git..."

    if pkg install -y git >/dev/null 2>&1; then
        ok "Git installed"
    else
        bad "Git installation failed"
        exit 1
    fi
fi

echo
echo "[3] CORE RUNTIME"
echo "--------------------------------------------------------------"

if command -v node >/dev/null 2>&1; then
    ok "Node.js available"
else
    echo "Installing Node.js..."

    if pkg install -y nodejs >/dev/null 2>&1; then
        ok "Node.js installed"
    else
        bad "Node.js installation failed"
        exit 1
    fi
fi

if command -v npm >/dev/null 2>&1; then
    ok "npm available"
else
    bad "npm unavailable"
fi

echo
echo "[4] NETWORK TOOLS"
echo "--------------------------------------------------------------"

if command -v curl >/dev/null 2>&1; then
    ok "curl available"
else
    echo "Installing curl..."

    if pkg install -y curl >/dev/null 2>&1; then
        ok "curl installed"
    else
        bad "curl installation failed"
    fi
fi

echo
echo "[5] REPOSITORY"
echo "--------------------------------------------------------------"

cd ~/request-runner || {
    bad "Request Runner® directory unavailable"
    exit 1
}

if [ -d .git ]; then
    ok "Git repository exists"
else
    echo "Initializing repository..."

    if git init >/dev/null 2>&1; then
        ok "Git repository initialized"
    else
        bad "Git repository initialization failed"
    fi
fi

echo
echo "[6] ENGINE FILES"
echo "--------------------------------------------------------------"

for file in \
    COMPLETION_ENGINE.sh \
    FINAL_PRODUCTION_SNAPSHOT.sh
do
    if [ -f "$file" ]; then
        ok "$file present"
    else
        bad "$file missing"
    fi
done

echo
echo "[7] NODE ENGINE"
echo "--------------------------------------------------------------"

if [ -d "$HOME/autonomous-platform" ]; then
    ok "Autonomous Platform® present"
else
    bad "Autonomous Platform® missing"
fi

echo
echo "[8] GIT SELF-TEST"
echo "--------------------------------------------------------------"

if git --version >/dev/null 2>&1; then
    ok "Git executable verified"
else
    bad "Git executable failed"
fi

echo
echo "[9] ENGINE RESTART"
echo "--------------------------------------------------------------"

if [ "$FAIL" -eq 0 ]; then
    ok "Bootstrap dependencies satisfied"
else
    bad "Bootstrap incomplete"
fi

echo
echo "=============================================================="
echo " SELF-BOOTSTRAP RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo
    echo "Completion Engine® can now restart."
else
    echo "STATUS: RED"
    exit 1
fi

echo "=============================================================="
