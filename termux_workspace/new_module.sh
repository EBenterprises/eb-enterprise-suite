#!/usr/bin/env bash
# ==============================================================================
# Executive Spectrum - Module Scaffolder
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

MODULE_NAME="${1}"

if [ -z "$MODULE_NAME" ]; then
    echo "Usage: ./exec-spec module <module_name>"
    exit 1
fi

MODULE_DIR="$HOME/termux_workspace/modules/$MODULE_NAME"

echo "[+] Scaffolding module: $MODULE_NAME at $MODULE_DIR..."
mkdir -p "$MODULE_DIR/src" "$MODULE_DIR/assets" "$MODULE_DIR/config"

cat << EOT > "$MODULE_DIR/README.md"
# $MODULE_NAME
EB Enterprises | Automated Terminal Module
EOT

cat << EOT > "$MODULE_DIR/src/main.py"
#!/usr/bin/env python3
def main():
    print("Module $MODULE_NAME initialized successfully.")

if __name__ == "__main__":
    main()
EOT

chmod +x "$MODULE_DIR/src/main.py"
echo "[+] Module '$MODULE_NAME' scaffolded successfully."
