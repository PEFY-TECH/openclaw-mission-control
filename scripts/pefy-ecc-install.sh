#!/usr/bin/env bash
set -euo pipefail

ECC_VERSION="${ECC_VERSION:-2.2.1}"
ECC_PACKAGE="ecc-universal@${ECC_VERSION}"
ECC_PROFILE="${ECC_PROFILE:-core}"
ECC_TARGET="${ECC_TARGET:-codex}"
ECC_REQUIRE_NATIVE_CODEX="${ECC_REQUIRE_NATIVE_CODEX:-0}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

log() { printf '[PEFY ECC] %s\n' "$*"; }
warn() { printf '[PEFY ECC] WARN: %s\n' "$*" >&2; }
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

if [[ "$ECC_TARGET" == "codex" ]]; then
  if command -v codex >/dev/null 2>&1; then
    log "Layer 2/2: installing ECC through the native Codex plugin lifecycle"
    ECC_VERSION="$ECC_VERSION" bash "$SCRIPT_DIR/pefy-ecc-codex-native.sh"
  elif [[ "$ECC_REQUIRE_NATIVE_CODEX" == "1" ]]; then
    fail "Codex CLI is required for native ECC activation but is not available on PATH"
  else
    warn "Codex CLI is unavailable; using the generic ECC Codex compatibility surface. This does not qualify native Codex plugin activation."
    npx --yes --package "$ECC_PACKAGE" ecc install --profile "$ECC_PROFILE" --target "$ECC_TARGET" --dry-run
    npx --yes --package "$ECC_PACKAGE" ecc install --profile "$ECC_PROFILE" --target "$ECC_TARGET"
  fi
else
  log "Layer 2/2: previewing governed harness install (profile=${ECC_PROFILE}, target=${ECC_TARGET})"
  npx --yes --package "$ECC_PACKAGE" ecc install --profile "$ECC_PROFILE" --target "$ECC_TARGET" --dry-run
  log "Applying governed harness install"
  npx --yes --package "$ECC_PACKAGE" ecc install --profile "$ECC_PROFILE" --target "$ECC_TARGET"
fi

log "Running ECC diagnostics"
ecc doctor
log "Inspecting installed ECC surfaces"
ecc list-installed

if [[ "$ECC_TARGET" == "codex" && -n "$(command -v codex 2>/dev/null || true)" ]]; then
  log "ECC ${ECC_VERSION}: global CLI installed; native Codex plugin installed and enabled."
elif [[ "$ECC_TARGET" == "codex" ]]; then
  log "ECC ${ECC_VERSION}: global CLI installed; Codex compatibility surface installed (native plugin not qualified)."
else
  log "ECC ${ECC_VERSION}: global CLI and ${ECC_TARGET} harness surface installed successfully."
fi
