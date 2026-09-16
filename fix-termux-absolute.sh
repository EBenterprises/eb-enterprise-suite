# 1. Force install the Linux ARM64 SWC binary, ignoring platform checks
npm install --save-dev --force @next/swc-linux-arm64-gnu

# 2. Create the Android ARM64 target directory
mkdir -p node_modules/@next/swc-android-arm64

# 3. Locate and copy the binary native file
SWC_PKG="node_modules/@next/swc-linux-arm64-gnu"
if [ -f "$SWC_PKG/native.napi.node" ]; then
  cp "$SWC_PKG/native.napi.node" node_modules/@next/swc-android-arm64/native.napi.node
elif [ -f "$SWC_PKG/swc.linux-arm64-gnu.node" ]; then
  cp "$SWC_PKG/swc.linux-arm64-gnu.node" node_modules/@next/swc-android-arm64/native.napi.node
fi

# 4. Create a valid package.json manifest for the bridged module
cat << 'BEEP' > node_modules/@next/swc-android-arm64/package.json
{
  "name": "@next/swc-android-arm64",
  "version": "14.1.0",
  "main": "native.napi.node"
}
BEEP

echo "SWC package successfully forced and bridged for Termux!"
