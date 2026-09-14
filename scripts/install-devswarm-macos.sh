#!/usr/bin/env bash
set -euo pipefail

# PEFY verified installer for the approved DevSwarm workstation baseline.
# Supported target: macOS ARM64. This script never disables Gatekeeper and
# never passes user credentials/tokens to DevSwarm.

URL="${PEFY_DEVSWARM_URL:-https://downloads.devswarm.ai/darwin/arm64/DevSwarm.dmg}"
EXPECTED_VERSION="${PEFY_DEVSWARM_EXPECTED_VERSION:-2.5.0}"
EXPECTED_SHA256="${PEFY_DEVSWARM_EXPECTED_SHA256:-}"
EXPECTED_TEAM_ID="${PEFY_DEVSWARM_EXPECTED_TEAM_ID:-}"
INSTALL_DIR="${PEFY_DEVSWARM_INSTALL_DIR:-/Applications}"
LAUNCH_AFTER_INSTALL="${PEFY_DEVSWARM_LAUNCH:-0}"
KEEP_DOWNLOAD="${PEFY_DEVSWARM_KEEP_DOWNLOAD:-0}"
EVIDENCE_DIR="${PEFY_DEVSWARM_EVIDENCE_DIR:-$HOME/DevSwarm-PEFY-Evidence}"

fail() { printf '[PEFY-DEVSWARM][FAIL] %s\n' "$*" >&2; exit "${2:-1}"; }
log() { printf '[PEFY-DEVSWARM] %s\n' "$*"; }

[[ "$(uname -s)" == "Darwin" ]] || fail "This installer requires macOS" 10
[[ "$(uname -m)" == "arm64" ]] || fail "PEFY DevSwarm baseline requires Apple Silicon (arm64)" 11
for cmd in curl hdiutil codesign spctl shasum plutil ditto; do
  command -v "$cmd" >/dev/null 2>&1 || fail "Required command missing: $cmd" 12
done

mkdir -p "$EVIDENCE_DIR"
work_dir="$(mktemp -d)"
dmg="$work_dir/DevSwarm.dmg"
mount_dir="$work_dir/mount"
mkdir -p "$mount_dir"
mounted=0
cleanup() {
  if [[ "$mounted" == "1" ]]; then
    hdiutil detach "$mount_dir" -quiet || true
  fi
  if [[ "$KEEP_DOWNLOAD" == "1" && -f "$dmg" ]]; then
    cp "$dmg" "$EVIDENCE_DIR/DevSwarm.dmg"
  fi
  rm -rf "$work_dir"
}
trap cleanup EXIT

log "Downloading approved DevSwarm channel over HTTPS"
curl --fail --location --proto '=https' --tlsv1.2 --output "$dmg" "$URL"
sha="$(shasum -a 256 "$dmg" | awk '{print $1}')"
printf '%s  %s\n' "$sha" "DevSwarm.dmg" > "$EVIDENCE_DIR/DevSwarm.dmg.sha256"
printf 'url=%s\nretrieved_utc=%s\nsha256=%s\n' "$URL" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$sha" > "$EVIDENCE_DIR/installer.env"

if [[ -n "$EXPECTED_SHA256" && "$sha" != "$EXPECTED_SHA256" ]]; then
  fail "Installer SHA-256 mismatch" 20
fi

# Validate the signed disk image with the platform security service. A local
# hash alone is not publisher-authenticity evidence.
spctl --assess --type open --context context:primary-signature --verbose=4 "$dmg" \
  > "$EVIDENCE_DIR/dmg-spctl.txt" 2>&1 || {
    cat "$EVIDENCE_DIR/dmg-spctl.txt" >&2
    fail "Gatekeeper rejected the DevSwarm disk image" 21
  }

hdiutil attach "$dmg" -nobrowse -readonly -mountpoint "$mount_dir" -quiet
mounted=1
app="$mount_dir/DevSwarm.app"
[[ -d "$app" ]] || fail "DevSwarm.app was not found in the signed disk image" 22

codesign --verify --deep --strict --verbose=2 "$app" \
  > "$EVIDENCE_DIR/codesign-verify.txt" 2>&1 || {
    cat "$EVIDENCE_DIR/codesign-verify.txt" >&2
    fail "DevSwarm application code signature verification failed" 23
  }
codesign -dv --verbose=4 "$app" > "$EVIDENCE_DIR/codesign-details.txt" 2>&1
spctl --assess --type execute --verbose=4 "$app" > "$EVIDENCE_DIR/app-spctl.txt" 2>&1 || {
  cat "$EVIDENCE_DIR/app-spctl.txt" >&2
  fail "Gatekeeper rejected DevSwarm.app" 24
}

version="$(plutil -extract CFBundleShortVersionString raw "$app/Contents/Info.plist" 2>/dev/null || true)"
[[ -n "$version" ]] || fail "Could not determine DevSwarm application version" 25
[[ "$version" == "$EXPECTED_VERSION" ]] || fail "Unexpected DevSwarm version: got $version, expected $EXPECTED_VERSION" 26

team_id="$(sed -n 's/^TeamIdentifier=//p' "$EVIDENCE_DIR/codesign-details.txt" | head -n 1)"
printf 'version=%s\nteam_id=%s\n' "$version" "$team_id" >> "$EVIDENCE_DIR/installer.env"
if [[ -n "$EXPECTED_TEAM_ID" && "$team_id" != "$EXPECTED_TEAM_ID" ]]; then
  fail "Unexpected Apple signing TeamIdentifier: got '$team_id', expected '$EXPECTED_TEAM_ID'" 27
fi

mkdir -p "$INSTALL_DIR"
target="$INSTALL_DIR/DevSwarm.app"
if [[ -e "$target" ]]; then
  installed_version="$(plutil -extract CFBundleShortVersionString raw "$target/Contents/Info.plist" 2>/dev/null || true)"
  log "Replacing existing DevSwarm installation (version=${installed_version:-unknown})"
  rm -rf "$target" 2>/dev/null || fail "Cannot replace $target; re-run with appropriate local administrator rights" 28
fi

ditto "$app" "$target" || fail "Failed to copy DevSwarm.app into $INSTALL_DIR" 29
codesign --verify --deep --strict --verbose=2 "$target" >/dev/null 2>&1 \
  || fail "Installed DevSwarm signature verification failed after copy" 30
spctl --assess --type execute --verbose=4 "$target" >/dev/null 2>&1 \
  || fail "Installed DevSwarm failed Gatekeeper assessment" 31

log "DevSwarm $version installed and signature-verified at $target"
log "Evidence directory: $EVIDENCE_DIR"
log "Next: launch DevSwarm, sign in interactively, authorize only approved integrations, add the repository, then run PEFY_REQUIRE_DEVSWARM=1 scripts/pefy-modernization-preflight.sh"

if [[ "$LAUNCH_AFTER_INSTALL" == "1" ]]; then
  open "$target"
  log "DevSwarm launched. Complete sign-in interactively; no credentials are handled by this script."
fi
