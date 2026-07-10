// AetherUI single-file bundler
// Merges src/ + vendor/Fusion into dist/AetherUI.lua for standalone
// executor usage via: loadstring(game:HttpGet("<raw-url>"))()
//
// Usage: node scripts/bundle.mjs
//
// How it works:
//   1. Every .lua file becomes a module keyed by its dot-path
//      ("Core.Theme", "Components.Button", "Fusion.State.Value", ...).
//      A folder's init.lua takes the folder's own key ("Types", "Fusion").
//   2. Roblox instance-path requires — require(script.Parent.X) and
//      alias forms (local Package = script.Parent.Parent) — are statically
//      resolved to module keys and rewritten to require("Key").
//   3. Each module body is wrapped in a closure that receives the bundle's
//      lazy `require`, and the whole file ends with `return require("Init")`.

import { readFileSync, writeFileSync, mkdirSync, readdirSync, statSync } from "node:fs";
import { join, dirname, relative, sep } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const srcDir = join(root, "src");
const fusionDir = join(root, "vendor", "Fusion");
const outFile = join(root, "dist", "AetherUI.lua");

// ---------------------------------------------------------------------------
// Collect modules
// ---------------------------------------------------------------------------

/** @type {Map<string, string>} key -> source */
const modules = new Map();

function walk(dir, cb) {
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) walk(full, cb);
    else cb(full);
  }
}

function addTree(baseDir, prefix) {
  walk(baseDir, (file) => {
    if (!file.endsWith(".lua")) return;
    let rel = relative(baseDir, file).split(sep).join(".").replace(/\.lua$/, "");
    // Folder init.lua takes the folder's key; a root init.lua takes the prefix itself.
    if (rel === "init") rel = "";
    else if (rel.endsWith(".init")) rel = rel.slice(0, -".init".length);
    const key = [prefix, rel].filter(Boolean).join(".");
    if (!key) throw new Error(`Unkeyed module: ${file}`);
    if (modules.has(key)) throw new Error(`Duplicate module key: ${key}`);
    modules.set(key, readFileSync(file, "utf8"));
  });
}

addTree(srcDir, "");
addTree(fusionDir, "Fusion");

// The runtime Fusion resolver is replaced by the vendored bundle.
modules.set(
  "Core.Fusion",
  `-- Vendored Fusion 0.2 (github.com/dphfox/Fusion, MIT) — bundled below.\nreturn require("Fusion")\n`
);

// ---------------------------------------------------------------------------
// Rewrite requires
// ---------------------------------------------------------------------------

/**
 * Resolves an instance-path chain (["script","Parent","Core","Theme"]) against
 * a module's own key segments to a bundle key string, or null if unresolvable.
 */
function resolveChain(startSegments, tokens) {
  const segs = [...startSegments];
  for (const tok of tokens) {
    if (tok === "Parent") {
      if (segs.length === 0) return null;
      segs.pop();
    } else {
      segs.push(tok);
    }
  }
  return segs.join(".");
}

const CHAIN = String.raw`[A-Za-z_]\w*(?:\s*\.\s*\w+)*`;

let rewrittenCount = 0;

for (const [key, source] of modules) {
  if (key === "Core.Fusion") continue;
  const own = key.split(".");
  /** @type {Map<string, string[]>} alias name -> resolved segments */
  const aliases = new Map();
  let out = source;

  // Pass 1: alias declarations — `local Package = script.Parent.Parent`
  out = out.replace(
    new RegExp(String.raw`^([ \t]*)local\s+(\w+)\s*=\s*(script(?:\s*\.\s*\w+)*)\s*$`, "gm"),
    (line, indent, name, chain) => {
      const tokens = chain.split(".").map((t) => t.trim()).slice(1);
      const resolvedKey = resolveChain(own, tokens);
      if (resolvedKey === null) return line;
      aliases.set(name, resolvedKey.length === 0 ? [] : resolvedKey.split("."));
      return `${indent}-- [bundled] alias inlined: ${name} = ${chain.replace(/\s+/g, "")}`;
    }
  );

  // Pass 2: require(script...) and require(Alias...) → require("Key")
  out = out.replace(new RegExp(String.raw`require\s*\(\s*(${CHAIN})\s*\)`, "g"), (whole, chain) => {
    const tokens = chain.split(".").map((t) => t.trim());
    const head = tokens.shift();
    let start;
    if (head === "script") start = own;
    else if (aliases.has(head)) start = aliases.get(head);
    else return whole; // dynamic require (e.g. pcall'd) — leave untouched
    const resolved = resolveChain(start, tokens);
    if (resolved === null || !modules.has(resolved)) {
      throw new Error(`[${key}] cannot resolve require(${chain}) -> ${resolved}`);
    }
    rewrittenCount++;
    return `require("${resolved}")`;
  });

  // Pass 3: `export type` is illegal inside a function body — demote to local.
  out = out.replace(/^([ \t]*)export\s+type\b/gm, "$1type");

  modules.set(key, out);
}

// Safety: no unresolved instance-path requires may remain.
for (const [key, source] of modules) {
  const leftover = source.match(new RegExp(String.raw`require\s*\(\s*(?:script|Package|Core|Components|Hooks)\b[^)"]*\)`, "g"));
  if (leftover) throw new Error(`[${key}] unresolved requires: ${leftover.join(", ")}`);
}

// ---------------------------------------------------------------------------
// Emit bundle
// ---------------------------------------------------------------------------

const header = `--[[
	AetherUI — single-file standalone bundle
	Generated by scripts/bundle.mjs — DO NOT EDIT BY HAND.

	Usage:
		local AetherUI = loadstring(game:HttpGet("<raw-url-to-this-file>"))()

	The UI parents to CoreGui (or gethui() when available) and persists
	across respawns. Includes vendored Fusion 0.2
	(github.com/dphfox/Fusion, MIT license — see vendor/Fusion/LICENSE).
]]

local __modules = {}
local __cache = {}

local function __register(key, fn)
	__modules[key] = fn
end

local function __require(key)
	local hit = __cache[key]
	if hit ~= nil then
		return hit.value
	end
	local fn = __modules[key]
	if fn == nil then
		error("[AetherUI bundle] unknown module: " .. tostring(key), 2)
	end
	__cache[key] = { value = nil } -- guard against circular requires
	local value = fn(__require)
	__cache[key] = { value = value }
	return value
end
`;

const parts = [header];
// Deterministic order: Fusion first, then core, then everything else, Init last.
const keys = [...modules.keys()].sort((a, b) => {
  const rank = (k) => (k === "Init" ? 3 : k.startsWith("Fusion") ? 0 : k.startsWith("Core") || k === "Types" ? 1 : 2);
  return rank(a) - rank(b) || a.localeCompare(b);
});
for (const key of keys) {
  parts.push(`__register(${JSON.stringify(key)}, function(require)\n${modules.get(key)}\nend)\n`);
}
parts.push(`return __require("Init")\n`);

mkdirSync(dirname(outFile), { recursive: true });
writeFileSync(outFile, parts.join("\n"));

console.log(`Bundled ${modules.size} modules (${rewrittenCount} requires rewritten)`);
console.log(`-> ${relative(root, outFile)} (${(parts.join("\n").length / 1024).toFixed(1)} KB)`);
