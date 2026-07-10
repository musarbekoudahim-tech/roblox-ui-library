// Combines the Roblox mock + the dist bundle (wrapped in an IIFE) + the smoke
// driver into one Luau file, so the whole library can be executed and every
// component constructed outside Roblox using the `luau` CLI:
//
//   node scripts/bundle.mjs && node scripts/smoke.mjs && luau /tmp/aetherui_smoke.lua
//
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");

const mock = readFileSync(join(root, "tests/mock_roblox.lua"), "utf8")
  // The mock ends with `return true` for module use; strip it for inlining.
  .replace(/\nreturn true\s*$/, "\n");

const bundle = readFileSync(join(root, "dist/AetherUI.lua"), "utf8");
const driver = readFileSync(join(root, "tests/smoke_driver.lua"), "utf8");

const combined = [
  "-- AUTO-GENERATED smoke test (scripts/smoke.mjs) — do not edit.",
  mock,
  "local AetherUI = (function()",
  bundle,
  "end)()",
  driver,
].join("\n");

const out = "/tmp/aetherui_smoke.lua";
writeFileSync(out, combined);
console.log(`wrote ${out} (${combined.length} bytes)`);
