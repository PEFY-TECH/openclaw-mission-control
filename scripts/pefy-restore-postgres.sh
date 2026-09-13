#!/usr/bin/env bash
set -euo pipefail

log() { printf '[PEFY-RESTORE] %s\n' "$*"; }
fail() { printf '[PEFY-RESTORE][FAIL] %s\n' "$*" >&2; exit 1; }

BACKUP_FILE="${1:-}"
MANIFEST_FILE="${2:-}"
IDENTITY_FILE="${PEFY_BACKUP_AGE_IDENTITY:-}"
COMPOSE_FILE="${PEFY_PRODUCTION_COMPOSE_FILE:-compose.production.yml}"
ENV_FILE="${PEFY_PRODUCTION_ENV_FILE:-}"
CONFIRM="${PEFY_RESTORE_CONFIRM:-}"

[[ -n "$BACKUP_FILE" && -n "$MANIFEST_FILE" ]] || fail "Usage: $0 <backup.dump.age> <backup.manifest>"
[[ -f "$BACKUP_FILE" ]] || fail "Backup not found: $BACKUP_FILE"
[[ -f "$MANIFEST_FILE" ]] || fail "Manifest not found: $MANIFEST_FILE"
[[ -f "$COMPOSE_FILE" ]] || fail "Production compose file not found: $COMPOSE_FILE"
[[ -n "$IDENTITY_FILE" && -f "$IDENTITY_FILE" ]] || fail "PEFY_BACKUP_AGE_IDENTITY must reference the age private identity file"
[[ "$CONFIRM" == "RESTORE_PRODUCTION_DATA" ]] || fail "Set PEFY_RESTORE_CONFIRM=RESTORE_PRODUCTION_DATA to authorize this destructive operation"
command -v age >/dev/null 2>&1 || fail "age is required"
command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required"
command -v docker >/dev/null 2>&1 || fail "docker is required"

expected_sha="$(awk -F= '$1=="sha256" {print $2}' "$MANIFEST_FILE")"
expected_file="$(awk -F= '$1=="file" {print $2}' "$MANIFEST_FILE")"
expected_encrypted="$(awk -F= '$1=="encrypted" {print $2}' "$MANIFEST_FILE")"
[[ "$expected_encrypted" == "true" ]] || fail "Manifest does not assert encrypted=true"
[[ "$expected_file" == "$(basename "$BACKUP_FILE")" ]] || fail "Manifest filename does not match backup"
[[ -n "$expected_sha" ]] || fail "Manifest SHA-256 is missing"
actual_sha="$(sha256sum "$BACKUP_FILE" | awk '{print $1}')"
[[ "$actual_sha" == "$expected_sha" ]] || fail "Backup SHA-256 mismatch"

compose=(docker compose -f "$COMPOSE_FILE")
if [[ -n "$ENV_FILE" ]]; then
  [[ -f "$ENV_FILE" ]] || fail "Environment file not found: $ENV_FILE"
  compose+=(--env-file "$ENV_FILE")
fi

log "Backup checksum verified"
log "Testing database service availability"
"${compose[@]}" exec -T db sh -ceu 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null'

log "Restoring encrypted custom-format backup into the configured database"
age --decrypt --identity "$IDENTITY_FILE" "$BACKUP_FILE" \
  | "${compose[@]}" exec -T db sh -ceu '
      exec pg_restore \
        --clean \
        --if-exists \
        --exit-on-error \
        --no-owner \
        --no-acl \
        --username "$POSTGRES_USER" \
        --dbname "$POSTGRES_DB"
    '

log "Restore completed; validating database availability"
"${compose[@]}" exec -T db sh -ceu 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null'
log "Database restore completed. Application readiness and smoke tests remain mandatory before traffic is accepted."
