import test from "node:test";
import assert from "node:assert/strict";
import { parseOmega } from "../src/core/parser.js";

test("OMEGA root declaration", () => {
  const x = parseOmega(`
omega "OMEGA"
system {
  version "1.0.0"
}
`);
  assert.equal(x.name, "OMEGA");
  assert.equal(x.system.version, "1.0.0");
});

test("OMEGA booleans", () => {
  const x = parseOmega(`
omega "OMEGA"
system {
  enabled true
  autonomous false
}
`);
  assert.equal(x.system.enabled, true);
  assert.equal(x.system.autonomous, false);
});
