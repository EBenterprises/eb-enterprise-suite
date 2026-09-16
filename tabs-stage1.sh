#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

APP="${TABS_APP_DIR:-$HOME/tabs-ledger}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP="$HOME/tabs-ledger-backups/$STAMP"

green='\033[32m'
yellow='\033[33m'
reset='\033[0m'

ok() { printf "${green}✓${reset} %s\n" "$*"; }
warn() { printf "${yellow}⚠${reset} %s\n" "$*"; }

command -v node >/dev/null || {
  echo "Node.js is required."
  exit 1
}

command -v npm >/dev/null || {
  echo "npm is required."
  exit 1
}

NODE_MAJOR="$(node -p 'Number(process.versions.node.split(".")[0])')"

if [ "$NODE_MAJOR" -lt 22 ]; then
  echo "Node 22+ required. Detected Node $NODE_MAJOR."
  exit 1
fi

mkdir -p "$HOME/tabs-ledger-backups"

if [ -d "$APP" ]; then
  mkdir -p "$BACKUP"
  cp -a "$APP/." "$BACKUP/"
  ok "Existing project backed up:"
  printf '  %s\n' "$BACKUP"
else
  mkdir -p "$APP"
  ok "Created $APP"
fi

mkdir -p \
  "$APP/app/api/health" \
  "$APP/app/api/customers" \
  "$APP/app/api/transactions" \
  "$APP/app/api/payments" \
  "$APP/app/api/reconcile" \
  "$APP/app/api/backup" \
  "$APP/app/api/import/legacy" \
  "$APP/app/customers/[id]" \
  "$APP/components" \
  "$APP/core/domain" \
  "$APP/core/application" \
  "$APP/core/integrity" \
  "$APP/core/security" \
  "$APP/core/serialization" \
  "$APP/database/migrations" \
  "$APP/database/repositories" \
  "$APP/database" \
  "$APP/scripts" \
  "$APP/types" \
  "$APP/data" \
  "$APP/backups"

ok "Directory architecture created."

cat > "$APP/package.json" <<'__PKG__'
{
  "name": "tabs-ledger",
  "version": "2.0.0",
  "private": true,
  "description": "Tabs® end-game local-first ledger platform",
  "scripts": {
    "dev": "next dev --webpack",
    "build": "next build --webpack",
    "start": "NODE_ENV=production node server.mjs",
    "typecheck": "tsc --noEmit",
    "verify": "npm run typecheck && npm run build",
    "db:verify": "node scripts/db-verify.mjs",
    "db:backup": "node scripts/db-backup.mjs",
    "db:reconcile": "node scripts/db-reconcile.mjs"
  },
  "dependencies": {
    "next": "16.3.0",
    "react": "19.2.0",
    "react-dom": "19.2.0"
  },
  "devDependencies": {
    "@types/node": "^24.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "typescript": "^5.9.0"
  }
}
__PKG__

cat > "$APP/tsconfig.json" <<'__TS__'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "es2022"],
    "allowJs": false,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts",
    "**/*.tsx",
    ".next/types/**/*.ts"
  ],
  "exclude": ["node_modules"]
}
__TS__

cat > "$APP/next-env.d.ts" <<'__NEXTENV__'
/// <reference types="next" />
/// <reference types="next/image-types/global" />
__NEXTENV__

cat > "$APP/next.config.ts" <<'__NEXTCONFIG__'
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false
};

export default nextConfig;
__NEXTCONFIG__

cat > "$APP/server.mjs" <<'__SERVER__'
import { createServer } from "node:http";
import next from "next";

const port = Number(process.env.PORT || 3000);
const hostname = process.env.HOST || "127.0.0.1";
const dev = process.env.NODE_ENV !== "production";

const app = next({
  dev,
  hostname,
  port
});

const handle = app.getRequestHandler();

await app.prepare();

createServer((req, res) => {
  handle(req, res);
}).listen(port, hostname, () => {
  console.log(`Tabs® → http://${hostname}:${port}`);
});
__SERVER__

cat > "$APP/.gitignore" <<'__GITIGNORE__'
node_modules/
.next/
*.log

.env
.env.*
!.env.example

data/*.sqlite
data/*.sqlite-shm
data/*.sqlite-wal

backups/*
!backups/.gitkeep
__GITIGNORE__

touch "$APP/backups/.gitkeep"

cd "$APP"

npm install

ok "Dependencies installed."

printf '\n'
ok "STAGE 1 COMPLETE"
printf '%s\n' "Project: $APP"
printf '%s\n' "Backup:  $BACKUP"
printf '\n'
printf '%s\n' "Run Stage 2:"
printf '%s\n' "bash ~/tabs-stage2.sh"
