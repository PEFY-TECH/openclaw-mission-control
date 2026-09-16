#!/usr/bin/env bash
set -euo pipefail

ECC_VERSION="${ECC_VERSION:-2.2.1}"
ECC_REF="${ECC_REF:-v${ECC_VERSION}}"
ECC_MARKETPLACE_SOURCE="${ECC_MARKETPLACE_SOURCE:-affaan-m/ECC}"
ECC_PLUGIN_SELECTOR="${ECC_PLUGIN_SELECTOR:-ecc@ecc}"

log() { printf '[PEFY ECC CODEX] %s\n' "$*"; }
fail() { printf '[PEFY ECC CODEX] ERROR: %s\n' "$*" >&2; exit 1; }

for cmd in codex node git; do
  command -v "$cmd" >/dev/null 2>&1 || fail "required command not found: $cmd"
done

marketplace_json="$(mktemp)"
plugin_json="$(mktemp)"
list_json="$(mktemp)"
cleanup() { rm -f "$marketplace_json" "$plugin_json" "$list_json"; }
trap cleanup EXIT

log "Registering pinned ECC marketplace ${ECC_MARKETPLACE_SOURCE}@${ECC_REF}"
if ! codex plugin marketplace add "$ECC_MARKETPLACE_SOURCE" --ref "$ECC_REF" --json >"$marketplace_json"; then
  fail "Codex marketplace registration failed. Refusing to replace or reinterpret an existing marketplace configuration."
fi

node - "$marketplace_json" <<'NODE'
const fs = require('fs');
const file = process.argv[2];
const data = JSON.parse(fs.readFileSync(file, 'utf8'));
if (data.marketplaceName !== 'ecc') {
  throw new Error(`unexpected marketplace name: ${data.marketplaceName}`);
}
if (typeof data.installedRoot !== 'string' || data.installedRoot.length === 0) {
  throw new Error('marketplace installedRoot is missing');
}
NODE

log "Installing or refreshing native Codex plugin ${ECC_PLUGIN_SELECTOR}"
codex plugin add "$ECC_PLUGIN_SELECTOR" --json >"$plugin_json"

node - "$plugin_json" "$ECC_VERSION" <<'NODE'
const fs = require('fs');
const path = require('path');
const [file, expectedVersion] = process.argv.slice(2);
const data = JSON.parse(fs.readFileSync(file, 'utf8'));
if (data.name !== 'ecc' || data.marketplaceName !== 'ecc') {
  throw new Error(`unexpected plugin identity: ${data.name}@${data.marketplaceName}`);
}
if (data.version !== expectedVersion) {
  throw new Error(`ECC plugin version mismatch: expected ${expectedVersion}, got ${data.version}`);
}
if (typeof data.installedPath !== 'string' || !path.isAbsolute(data.installedPath)) {
  throw new Error('Codex returned a missing or non-absolute installedPath');
}
NODE

log "Verifying ECC is installed and enabled in Codex"
codex plugin list --json >"$list_json"

node - "$list_json" "$ECC_VERSION" <<'NODE'
const fs = require('fs');
const [file, expectedVersion] = process.argv.slice(2);
const data = JSON.parse(fs.readFileSync(file, 'utf8'));
const installed = Array.isArray(data.installed) ? data.installed : [];
const ecc = installed.find((entry) => entry.name === 'ecc' && entry.marketplaceName === 'ecc');
if (!ecc) throw new Error('ECC is absent from Codex installed plugins');
if (ecc.version !== expectedVersion) {
  throw new Error(`installed ECC plugin version mismatch: expected ${expectedVersion}, got ${ecc.version}`);
}
if (ecc.installed !== true) throw new Error('ECC plugin is not marked installed');
if (ecc.enabled !== true) {
  throw new Error('ECC plugin is installed but not enabled; activation is incomplete');
}
NODE

log "Native Codex ECC plugin is installed and enabled at version ${ECC_VERSION}."
log "Codex hook trust remains provider-managed and is intentionally not bypassed."
