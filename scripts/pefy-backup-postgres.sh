#!/usr/bin/env bash
set -euo pipefail

log() { printf '[PEFY-BACKUP] %s\n' "$*"; }
fail() { printf '[PEFY-BACKUP][FAIL] %s\n' "$*" >&2; exit 1; }

COMPOSE_FILE="${PEFY_PRODUCTION_COMPOSE_FILE:-compose.production.yml}"
ENV_FILE="${PEFY_PRODUCTION_ENV_FILE:-}"
BACKUP_DIR="${PEFY_BACKUP_DIR:-./backups/mission-control}"
AGE_RECIPIENT="${PEFY_BACKUP_AGE_RECIPIENT:-}"

[[ -f "$COMPOSE_FILE" ]] || fail "Production compose file not found: $COMPOSE_FILE"
[[ -n "$AGE_RECIPIENT" ]] || fail "PEFY_BACKUP_AGE_RECIPIENT is required; unencrypted production backups are not accepted"
command -v docker >/dev/null 2>&1 || fail "docker is required"
command -v age >/dev/null 2>&1 || fail "age is required for encrypted backup"
command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required"

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

compose=(docker compose -f "$COMPOSE_FILE")
if [[ -n "$ENV_FILE" ]]; then
  [[ -f "$ENV_FILE" ]] || fail "Environment file not found: $ENV_FILE"
  compose+=(--env-file "$ENV_FILE")
fi

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
base="$BACKUP_DIR/mission-control-${timestamp}"
encrypted="$base.dump.age"
manifest="$base.manifest"

tmp_dump="$(mktemp)"
trap 'rm -f "$tmp_dump"' EXIT
chmod 600 "$tmp_dump"

log "Creating PostgreSQL custom-format dump"
"${compose[@]}" exec -T db sh -ceu '
  : "${POSTGRES_USER:?POSTGRES_USER missing}"
  : "${POSTGRES_DB:?POSTGRES_DB missing}"
  exec pg_dump --format=custom --no-owner --no-acl --username "$POSTGRES_USER" --dbname "$POSTGRES_DB"
' > "$tmp_dump"

[[ -s "$tmp_dump" ]] || fail "pg_dump produced an empty backup"

log "Encrypting backup with age"
age --recipient "$AGE_RECIPIENT" --output "$encrypted" "$tmp_dump"
chmod 600 "$encrypted"

size_bytes="$(wc -c < "$encrypted" | tr -d ' ')"
sha256="$(sha256sum "$encrypted" | awk '{print $1}')"

cat > "$manifest" <<EOF
created_at_utc=$timestamp
format=postgresql-custom+age
file=$(basename "$encrypted")
size_bytes=$size_bytes
sha256=$sha256
encrypted=true
compose_file=$COMPOSE_FILE
EOF
chmod 600 "$manifest"

log "Backup complete: $encrypted"
log "Manifest: $manifest"
log "SHA-256: $sha256"
