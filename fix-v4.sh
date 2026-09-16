# 1. Update Prisma schema with correct binary targets for Termux (Linux ARM64)
cat << 'BEEP' > prisma/schema.prisma
datasource db {
  provider = "sqlite"
  url      = "file:./dev.db"
}

generator client {
  provider      = "prisma-client-js"
  binaryTargets = ["native", "linux-arm64-openssl-3.0.x"]
}
BEEP

# 2. Configure Next.js to fully utilize Babel and bypass SWC checks
cat << 'BEEP' > next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: false,
}

module.exports = nextConfig
BEEP

# 3. Ensure Babel config is active
cat << 'BEEP' > .babelrc
{
  "presets": ["next/babel"]
}
BEEP

echo "Version 4 configuration applied successfully!"
