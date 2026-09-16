# 1. Install standard Babel dependencies required for custom compilation
npm install --save-dev @babel/core babel-loader

# 2. Create a Babel configuration file
cat << 'BEEP' > .babelrc
{
  "presets": ["next/babel"]
}
BEEP

# 3. Update next.config.js to handle custom compilation if needed
cat << 'BEEP' > next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
}

module.exports = nextConfig
BEEP

echo "Babel configuration applied successfully for Termux!"
