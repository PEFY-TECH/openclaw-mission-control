#!/usr/bin/env bash
set -euo pipefail

ECC_VERSION="${ECC_VERSION:-2.2.1}"
ECC_TARGET="${ECC_TARGET:-codex}"

log() { printf '[PEFY ECC STATUS] %s\n' "$*"; }
fail() { printf '[PEFY ECC STATUS] ERROR: %s\n' "$*" >&2; exit 1; }

for cmd in node npm npx; do
  command -v "$cmd" >/dev/null 2>&1 || fail "required command not found: $cmd"
done

command -v ecc >/dev/null 2>&1 || fail "ecc CLI is not installed on this host"

global_root="$(npm root -g)"
package_json="${global_root}/ecc-universal/package.json"
[[ -f "$package_json" ]] || fail "global ecc-universal package metadata not found at $package_json"

installed_version="$(node -e 'const p=require(process.argv[1]); process.stdout.write(String(p.version||""));' "$package_json")"
[[ "$installed_version" == "$ECC_VERSION" ]] || fail "ECC version mismatch: expected $ECC_VERSION, got ${installed_version:-<empty>}"

log "Global ECC CLI present: ecc-universal@$installed_version"
log "Running ECC doctor"
ecc doctor

log "Inspecting installed surfaces (expected target: $ECC_TARGET)"
ecc list-installed

log "Host ECC status: QUALIFIED for version $ECC_VERSION (diagnostics completed)."
