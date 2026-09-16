import fs from "node:fs";
import path from "node:path";

const ROOT = process.cwd();
let failures = 0;

const required = [
  "package.json",
  "next.config.js",
  "jsconfig.json",

  "apps/web/app/layout.js",
  "apps/web/app/page.js",
  "apps/web/app/globals.css",
  "apps/web/app/dashboard/page.js",
  "apps/web/app/errands/new/page.js",
  "apps/web/app/api/health/route.js",
  "apps/web/app/api/errands/route.js",

  "apps/web/components/Brand.js",
  "apps/web/components/Nav.js",

  "domain/errands/index.js",
  "domain/locations/index.js",
  "domain/users/index.js",
  "domain/runners/index.js",
  "domain/requests/index.js",

  "services/requests/index.js",
  "services/matching/index.js",
  "services/dispatch/index.js",
  "services/tracking/index.js",
  "services/pricing/index.js",
  "services/addressless-coordination/index.js",

  "security/authentication/index.js",
  "security/authorization/index.js",
  "security/audit/index.js",

  "events/registry/index.js",
  "events/publishers/index.js",

  "api/openapi/openapi.json",

  "database/schema/README.md",
  "database/migrations/0001_foundation.sql",

  "README.md"
];

function check(label, condition, detail = "") {
  if (condition) {
    console.log(`[OK]  ${label}`);
    return;
  }

  console.log(`[ERR] ${label}${detail ? ` - ${detail}` : ""}`);
  failures++;
}

console.log("");
console.log("==============================================");
console.log("        ERRANDS(R) BUILD VALIDATOR");
console.log("==============================================");
console.log(`ROOT: ${ROOT}`);
console.log("");

check(
  "Repository root",
  fs.existsSync(ROOT)
);

check(
  "package.json",
  fs.existsSync(path.join(ROOT, "package.json"))
);

check(
  "Next.js configuration",
  fs.existsSync(path.join(ROOT, "next.config.js"))
);

check(
  "Web application",
  fs.existsSync(path.join(ROOT, "apps/web"))
);

for (const file of required) {
  check(
    file,
    fs.existsSync(path.join(ROOT, file)),
    "missing"
  );
}

const packagePath = path.join(ROOT, "package.json");

if (fs.existsSync(packagePath)) {
  try {
    const pkg = JSON.parse(
      fs.readFileSync(packagePath, "utf8")
    );

    check("package.json syntax", true);
    check(
      "Next.js dependency",
      Boolean(pkg.dependencies?.next)
    );
    check(
      "React dependency",
      Boolean(pkg.dependencies?.react)
    );
    check(
      "dev script",
      Boolean(pkg.scripts?.dev)
    );
    check(
      "build script",
      Boolean(pkg.scripts?.build)
    );
  } catch (error) {
    check(
      "package.json syntax",
      false,
      error.message
    );
  }
}

const pagePath = path.join(
  ROOT,
  "apps/web/app/page.js"
);

if (fs.existsSync(pagePath)) {
  const source = fs.readFileSync(
    pagePath,
    "utf8"
  );

  check(
    "Home page branding",
    source.includes("ERRANDS")
  );

  check(
    "New errand route",
    source.includes("/errands/new")
  );
}

const cssPath = path.join(
  ROOT,
  "apps/web/app/globals.css"
);

if (fs.existsSync(cssPath)) {
  const css = fs.readFileSync(
    cssPath,
    "utf8"
  );

  check(
    "Global stylesheet",
    css.trim().length > 100
  );
}

const healthPath = path.join(
  ROOT,
  "apps/web/app/api/health/route.js"
);

if (fs.existsSync(healthPath)) {
  const source = fs.readFileSync(
    healthPath,
    "utf8"
  );

  check(
    "Health GET endpoint",
    source.includes("export async function GET")
  );
}

const errandsPath = path.join(
  ROOT,
  "apps/web/app/api/errands/route.js"
);

if (fs.existsSync(errandsPath)) {
  const source = fs.readFileSync(
    errandsPath,
    "utf8"
  );

  check(
    "Errands GET endpoint",
    source.includes("export async function GET")
  );

  check(
    "Errands POST endpoint",
    source.includes("export async function POST")
  );
}

console.log("");
console.log("==============================================");

if (failures === 0) {
  console.log("[OK]  GREEN");
  console.log("[OK]  ERRANDS(R) VALIDATION PASSED");
  console.log("[OK]  0 FAILURES");
  console.log("==============================================");
  process.exit(0);
}

console.log("[ERR] RED");
console.log("[ERR] ERRANDS(R) VALIDATION FAILED");
console.log(`[ERR] ${failures} FAILURE(S)`);
console.log("==============================================");

process.exit(1);
