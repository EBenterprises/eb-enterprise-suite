"use strict";

const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");

const required = [
  "config.json",
  "locales/registry.json",
  "catalog/LANGUAGE_CATALOG.json",
  "legal/legal-document.schema.json",
  "rtl/global.css",
  "locale-resolver.js"
];

let failures = 0;

for (const file of required) {
  const full = path.join(root, file);

  if (!fs.existsSync(full)) {
    console.error(`MISSING: ${file}`);
    failures++;
    continue;
  }

  console.log(`OK: ${file}`);
}

if (failures) {
  process.exit(1);
}

console.log("GLOBAL I18N AUDIT: PASS");
