#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[PEFY-PREFLIGHT][FAIL] $*" >&2; exit 1; }
pass() { echo "[PEFY-PREFLIGHT][PASS] $*"; }

command -v docker >/dev/null 2>&1 || fail "docker is required"
docker compose version >/dev/null 2>&1 || fail "docker compose v2 is required"
command -v python3 >/dev/null 2>&1 || fail "python3 is required"

python3 - <<'PY'
import json
from pathlib import Path
p = Path('pefy/agent-team.elite.json')
if not p.exists():
    raise SystemExit('missing pefy/agent-team.elite.json')
d = json.loads(p.read_text())
assert d['desired_mode'] == 'production'
assert d['team']['spawn_policy']['hard_limit'] <= 12
assert d['security_controls']['least_privilege'] is True
assert d['security_controls']['audit_logging'] == 'mandatory'
assert d['security_controls']['provenance'] == 'mandatory'
assert 'blind-upstream-rebase' in d['governance']['forbidden']
print('[PEFY-PREFLIGHT][PASS] elite profile validated')
PY

: "${AUTH_MODE:=local}"
: "${LOCAL_AUTH_TOKEN:=}"
: "${POSTGRES_PASSWORD:=}"

if [[ "$AUTH_MODE" == "local" ]]; then
  [[ ${#LOCAL_AUTH_TOKEN} -ge 50 ]] || fail "LOCAL_AUTH_TOKEN must be at least 50 characters in local auth mode"
fi

[[ -n "$POSTGRES_PASSWORD" ]] || fail "POSTGRES_PASSWORD must be explicitly set"
[[ "$POSTGRES_PASSWORD" != "postgres" ]] || fail "default PostgreSQL password is forbidden in production"

export AUTH_MODE LOCAL_AUTH_TOKEN POSTGRES_PASSWORD
export POSTGRES_USER="${POSTGRES_USER:-postgres}"
export POSTGRES_DB="${POSTGRES_DB:-mission_control}"
export BASE_URL="${BASE_URL:-http://localhost:8000}"
export CORS_ORIGINS="${CORS_ORIGINS:-http://localhost:3000}"
export NEXT_PUBLIC_API_URL="${NEXT_PUBLIC_API_URL:-auto}"

docker compose -f compose.yml config >/dev/null
pass "docker compose configuration validated"

SECRET_PATTERN='(^|[^A-Za-z0-9])(sk-(proj-)?[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY)'
if grep -RInE --exclude='*.example' --exclude='*.md' "$SECRET_PATTERN" pefy .github 2>/dev/null; then
  fail "potential committed secret detected"
fi
pass "basic secret-pattern scan passed"

pass "PEFY ΩAGENT TEAM ELITE preflight completed"
