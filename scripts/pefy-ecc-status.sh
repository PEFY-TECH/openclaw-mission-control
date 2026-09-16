#!/usr/bin/env bash
set -euo pipefail

ECC_VERSION="${ECC_VERSION:-2.2.1}"

log() { printf '[PEFY ECC STATUS] %s\n' "$*"; }
fail() { printf '[PEFY ECC STATUS] ERROR: %s\n' "$*" >&2; exit 1; }

for cmd in node npm ecc; do
  command -v "$cmd" >/dev/null 2>&1 || fail "required command not found: $cmd"
done

global_root="$(npm root -g)"
package_json="${global_root}/ecc-universal/package.json"
[[ -f "${package_json}" ]] || fail "ecc-universal package not found under npm global root"

installed_version="$(node -e 'const p=require(process.argv[1]); process.stdout.write(String(p.version||""));' "${package_json}")"
[[ "${installed_version}" == "${ECC_VERSION}" ]] || fail "ECC version mismatch: expected ${ECC_VERSION}, got ${installed_version:-<empty>}"

log "global CLI present: $(command -v ecc)"
log "ecc-universal version: ${installed_version}"

log "running ECC doctor"
ecc doctor

log "listing installed ECC surfaces"
ecc list-installed

log "ECC operational status check passed."
