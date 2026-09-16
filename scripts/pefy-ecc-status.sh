#!/usr/bin/env bash
set -euo pipefail

ECC_VERSION="${ECC_VERSION:-2.2.1}"
ECC_TARGET="${ECC_TARGET:-codex}"

log() { printf '[PEFY ECC STATUS] %s\n' "$*"; }
fail() { printf '[PEFY ECC STATUS] ERROR: %s\n' "$*" >&2; exit 1; }

for cmd in node npm ecc; do
  command -v "$cmd" >/dev/null 2>&1 || fail "required command not found: $cmd"
done

global_root="$(npm root -g)"
package_json="${global_root}/ecc-universal/package.json"
[[ -f "$package_json" ]] || fail "global ecc-universal package metadata not found at $package_json"

installed_version="$(node -e 'const p=require(process.argv[1]); process.stdout.write(String(p.version||""));' "$package_json")"
[[ "$installed_version" == "$ECC_VERSION" ]] || fail "ECC version mismatch: expected $ECC_VERSION, got ${installed_version:-<empty>}"

log "Global ECC CLI present: ecc-universal@$installed_version"
log "Running ECC doctor"
ecc doctor

if [[ "$ECC_TARGET" == "codex" ]]; then
  command -v codex >/dev/null 2>&1 || fail "Codex CLI is required to qualify native ECC activation"
  plugin_list="$(mktemp)"
  cleanup() { rm -f "$plugin_list"; }
  trap cleanup EXIT
  log "Verifying native Codex ECC plugin state"
  codex plugin list --json >"$plugin_list"
  node - "$plugin_list" "$ECC_VERSION" <<'NODE'
const fs = require('fs');
const [file, expectedVersion] = process.argv.slice(2);
const data = JSON.parse(fs.readFileSync(file, 'utf8'));
const installed = Array.isArray(data.installed) ? data.installed : [];
const ecc = installed.find((entry) => entry.name === 'ecc' && entry.marketplaceName === 'ecc');
if (!ecc) throw new Error('ECC is absent from Codex installed plugins');
if (ecc.version !== expectedVersion) throw new Error(`Codex ECC version mismatch: expected ${expectedVersion}, got ${ecc.version}`);
if (ecc.installed !== true) throw new Error('Codex ECC plugin is not marked installed');
if (ecc.enabled !== true) throw new Error('Codex ECC plugin is installed but not enabled');
NODE
  log "Native Codex ECC plugin is installed and enabled at version $ECC_VERSION"
  log "Hook trust remains Codex-managed and is not bypassed by PEFY automation"
else
  log "Inspecting installed ECC surfaces (expected target: $ECC_TARGET)"
  ecc list-installed
fi

log "Host ECC status: QUALIFIED for version $ECC_VERSION."
