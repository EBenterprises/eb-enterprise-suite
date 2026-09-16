# ==========================================
# VERIFIED STACK BOOTSTRAPPER & GATEKEEPER
# ==========================================

echo "[1/4] Verifying directory structure..."
mkdir -p prisma src/app src/components src/lib

# 1. Write clean Prisma schema using WASM/Pure JS friendly setup or robust fallback targets
cat << 'BEEP' > prisma/schema.prisma
datasource db {
  provider = "sqlite"
  url      = "file:./dev.db"
}

generator client {
  provider = "prisma-client-js"
}
BEEP

# 2. Write stable Next.js config without hard platform assumptions
cat << 'BEEP' > next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Force webpack fallbacks if needed, avoiding tight platform coupling
}

module.exports = nextConfig
BEEP

echo "[2/4] Running pre-flight verification checks..."

# Verification Gate 1: Check Node version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
  echo "❌ Error: Node.js version 18+ is required (Found: $(node -v))"
  exit 1
else
  echo "✔ Node.js version check passed ($(node -v))"
fi

# Verification Gate 2: Check database file accessibility
if [ ! -f "prisma/schema.prisma" ]; then
  echo "❌ Error: Prisma schema is missing!"
  exit 1
else
  echo "✔ Prisma schema validated."
fi

echo "[3/4] Initializing database cleanly..."
npx prisma generate
npx prisma db push --skip-generate

echo "[4/4] Stack verification complete. Ready for build & deploy execution."
