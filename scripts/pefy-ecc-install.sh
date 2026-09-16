#!/usr/bin/env bash
set -euo pipefail

ECC_VERSION="${ECC_VERSION:-2.2.1}"
ECC_PACKAGE="ecc-universal@${ECC_VERSION}"
ECC_PROFILE="${ECC_PROFILE:-core}"
ECC_TARGET="${ECC_TARGET:-codex}"

log() { printf '[PEFY ECC] %s\n' "$*"; }
fail() { printf '[PEFY ECC] ERROR: %s\n' "$*" >&2; exit 1; }

for cmd in node npm npx; do
  command -v "$cmd" >/dev/null 2>&1 || fail "required command not found: $cmd"
done

log "Validating published package ${ECC_PACKAGE}"
published_version="$(npm view "${ECC_PACKAGE}" version --silent)"
[[ "${published_version}" == "${ECC_VERSION}" ]] || fail "registry version mismatch: expected ${ECC_VERSION}, got ${published_version:-<empty>}"

log "Layer 1/2: installing pinned ECC CLI globally (${ECC_PACKAGE})"
npm install -g "${ECC_PACKAGE}"
command -v ecc >/dev/null 2>&1 || fail "global installation completed but ecc CLI is not on PATH"

global_root="$(npm root -g)"
installed_version="$(node -e 'const p=require(process.argv[1]); process.stdout.write(String(p.version||""));' "${global_root}/ecc-universal/package.json")"
[[ "${installed_version}" == "${ECC_VERSION}" ]] || fail "global ECC version mismatch: expected ${ECC_VERSION}, got ${installed_version:-<empty>}"

log "Layer 2/2: previewing governed harness install (profile=${ECC_PROFILE}, target=${ECC_TARGET})"
npx --yes --package "${ECC_PACKAGE}" ecc install \
  --profile "${ECC_PROFILE}" \
  --target "${ECC_TARGET}" \
  --dry-run

log "Applying governed harness install"
npx --yes --package "${ECC_PACKAGE}" ecc install \
  --profile "${ECC_PROFILE}" \
  --target "${ECC_TARGET}"

log "Running ECC diagnostics"
npx --yes --package "${ECC_PACKAGE}" ecc doctor

log "Inspecting installed ECC surfaces"
npx --yes --package "${ECC_PACKAGE}" ecc list-installed

log "ECC ${ECC_VERSION} dual-layer installation completed successfully."
