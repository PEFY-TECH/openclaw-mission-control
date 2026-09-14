#!/usr/bin/env bash
set -euo pipefail

log() { printf '[PEFY-SMOKE] %s\n' "$*"; }
fail() { printf '[PEFY-SMOKE][FAIL] %s\n' "$*" >&2; exit 1; }

BACKEND_URL="${PEFY_MC_BACKEND_URL:-}"
FRONTEND_URL="${PEFY_MC_FRONTEND_URL:-}"
AUTH_TOKEN="${PEFY_MC_LOCAL_AUTH_TOKEN:-}"
EVIDENCE_DIR="${PEFY_MC_EVIDENCE_DIR:-./artifacts/pefy-production-smoke}"

[[ -n "$BACKEND_URL" ]] || fail "PEFY_MC_BACKEND_URL is required"
[[ -n "$FRONTEND_URL" ]] || fail "PEFY_MC_FRONTEND_URL is required"

BACKEND_URL="${BACKEND_URL%/}"
FRONTEND_URL="${FRONTEND_URL%/}"
mkdir -p "$EVIDENCE_DIR"
chmod 700 "$EVIDENCE_DIR"

command -v curl >/dev/null 2>&1 || fail "curl is required"

probe_json() {
  local name="$1"
  local url="$2"
  local output="$EVIDENCE_DIR/${name}.json"
  local status_file="$EVIDENCE_DIR/${name}.status"
  local status_code
  status_code="$(curl --silent --show-error --connect-timeout 5 --max-time 15 \
    --output "$output" --write-out '%{http_code}' "$url")" || fail "$name request failed"
  printf '%s\n' "$status_code" > "$status_file"
  [[ "$status_code" == "200" ]] || fail "$name returned HTTP $status_code"
  python3 - "$output" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
if data.get("ok") is not True:
    raise SystemExit(f"probe did not return ok=true: {data!r}")
if set(data) != {"ok"}:
    raise SystemExit("health evidence contains fields beyond the approved non-sensitive ok flag")
PY
  chmod 600 "$output" "$status_file"
  log "$name: HTTP 200 / ok=true"
}

log "Checking backend liveness"
probe_json "healthz" "$BACKEND_URL/healthz"

log "Checking dependency-aware backend readiness"
probe_json "readyz" "$BACKEND_URL/readyz"

log "Checking Project Gallery surface without retaining response content"
GALLERY_STATUS="$(curl --silent --show-error --location --connect-timeout 5 --max-time 20 \
  --output /dev/null --write-out '%{http_code}' \
  "$FRONTEND_URL/project-gallery")" || fail "Project Gallery request failed"
printf '%s\n' "$GALLERY_STATUS" > "$EVIDENCE_DIR/project-gallery.status"
chmod 600 "$EVIDENCE_DIR/project-gallery.status"
[[ "$GALLERY_STATUS" =~ ^2[0-9][0-9]$ ]] || fail "Project Gallery returned HTTP $GALLERY_STATUS after redirects"
log "Project Gallery: HTTP $GALLERY_STATUS"

log "Proving unauthenticated access is denied without retaining response content"
DENIED_STATUS="$(curl --silent --show-error --connect-timeout 5 --max-time 15 \
  --output /dev/null --write-out '%{http_code}' \
  --request POST "$BACKEND_URL/api/v1/auth/bootstrap")" || fail "Unauthenticated denial probe failed"
printf '%s\n' "$DENIED_STATUS" > "$EVIDENCE_DIR/unauthenticated-bootstrap.status"
chmod 600 "$EVIDENCE_DIR/unauthenticated-bootstrap.status"
[[ "$DENIED_STATUS" == "401" ]] || fail "Expected unauthenticated bootstrap to be denied with HTTP 401; got $DENIED_STATUS"
log "Denied action proof: unauthenticated bootstrap returned HTTP 401"

AUTH_RESULT="not_run"
if [[ -n "$AUTH_TOKEN" ]]; then
  log "Checking authenticated bootstrap; token and user profile are never written to evidence"
  AUTH_STATUS="$(curl --silent --show-error --connect-timeout 5 --max-time 15 \
    --output /dev/null --write-out '%{http_code}' \
    --request POST --header "Authorization: Bearer $AUTH_TOKEN" \
    "$BACKEND_URL/api/v1/auth/bootstrap")" || fail "Authenticated bootstrap request failed"
  printf '%s\n' "$AUTH_STATUS" > "$EVIDENCE_DIR/authenticated-bootstrap.status"
  chmod 600 "$EVIDENCE_DIR/authenticated-bootstrap.status"
  [[ "$AUTH_STATUS" == "200" ]] || fail "Authenticated bootstrap returned HTTP $AUTH_STATUS"
  AUTH_RESULT="passed"
  log "Allowed action proof: authenticated bootstrap returned HTTP 200"
else
  log "PEFY_MC_LOCAL_AUTH_TOKEN not supplied; authenticated allowed-action proof remains intentionally pending"
fi

python3 - "$EVIDENCE_DIR" "$BACKEND_URL" "$FRONTEND_URL" "$GALLERY_STATUS" "$DENIED_STATUS" "$AUTH_RESULT" <<'PY'
import datetime as dt
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
summary = {
    "generated_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
    "backend_url": sys.argv[2],
    "frontend_url": sys.argv[3],
    "checks": {
        "healthz": "passed",
        "readyz": "passed",
        "project_gallery_http_status": int(sys.argv[4]),
        "unauthenticated_bootstrap_http_status": int(sys.argv[5]),
        "authenticated_bootstrap": sys.argv[6],
    },
    "secret_material_recorded": False,
    "identity_profile_recorded": False,
    "ui_response_body_recorded": False,
}
summary_path = out / "summary.json"
summary_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
summary_path.chmod(0o600)
PY

log "Smoke checks complete. Redacted evidence written to $EVIDENCE_DIR"
