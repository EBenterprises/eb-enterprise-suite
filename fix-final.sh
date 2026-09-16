# 1. Install the Linux ARM64 SWC binary package
npm install --save-dev @next/swc-linux-arm64-gnu

# 2. Create the missing target directory for Android ARM64 in node_modules
mkdir -p node_modules/@next/swc-android-arm64

# 3. Symlink the Linux ARM64 binary so Next.ses loader detects it successfully
if [ -f node_modules/@next/swc-linux-arm64-gnu/native.napi.node ]; then
  cp node_modules/@next/swc-linux-arm64-gnu/native.napi.node node_modules/@next/swc-android-arm64/native.napi.node
elif [ -f node_modules/@next/swc-linux-arm64-gnu/swc.android-arm64.node ]; then
  cp node_modules/@next/swc-linux-arm64-gnu/swc.* node_modules/@next/swc-android-arm64/
fi

# Create a dummy package.json for the android swc module so Next.js accepts it
cat << 'BEEP' > node_modules/@next/swc-android-arm64/package.json
{
  "name": "@next/swc-android-arm64",
  "version": "14.1.0",
  "main": "native.napi.node"
}
BEEP

echo "SWC binary bridged successfully for Termux!"
