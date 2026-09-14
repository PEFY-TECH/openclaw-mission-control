#!/usr/bin/env bash
set -euo pipefail

log() { printf '[PEFY-BACKUP-VERIFY] %s\n' "$*"; }
fail() { printf '[PEFY-BACKUP-VERIFY][FAIL] %s\n' "$*" >&2; exit 1; }

BACKUP_FILE="${1:-}"
MANIFEST_FILE="${2:-}"
IDENTITY_FILE="${PEFY_BACKUP_AGE_IDENTITY:-}"

[[ -n "$BACKUP_FILE" ]] || fail "Usage: $0 <backup.dump.age> <backup.manifest>"
[[ -n "$MANIFEST_FILE" ]] || fail "Usage: $0 <backup.dump.age> <backup.manifest>"
[[ -f "$BACKUP_FILE" ]] || fail "Backup not found: $BACKUP_FILE"
[[ -f "$MANIFEST_FILE" ]] || fail "Manifest not found: $MANIFEST_FILE"
[[ -n "$IDENTITY_FILE" && -f "$IDENTITY_FILE" ]] || fail "PEFY_BACKUP_AGE_IDENTITY must reference the age private identity file"
command -v age >/dev/null 2>&1 || fail "age is required"
command -v pg_restore >/dev/null 2>&1 || fail "pg_restore is required for structural verification"
command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required"

expected_sha="$(awk -F= '$1=="sha256" {print $2}' "$MANIFEST_FILE")"
expected_file="$(awk -F= '$1=="file" {print $2}' "$MANIFEST_FILE")"
expected_encrypted="$(awk -F= '$1=="encrypted" {print $2}' "$MANIFEST_FILE")"

[[ "$expected_encrypted" == "true" ]] || fail "Manifest does not assert encrypted=true"
[[ "$expected_file" == "$(basename "$BACKUP_FILE")" ]] || fail "Manifest filename does not match backup"
[[ -n "$expected_sha" ]] || fail "Manifest SHA-256 is missing"

actual_sha="$(sha256sum "$BACKUP_FILE" | awk '{print $1}')"
[[ "$actual_sha" == "$expected_sha" ]] || fail "Backup SHA-256 mismatch"
log "Encrypted artifact checksum: OK"

tmp_dump="$(mktemp)"
trap 'rm -f "$tmp_dump"' EXIT
chmod 600 "$tmp_dump"
age --decrypt --identity "$IDENTITY_FILE" --output "$tmp_dump" "$BACKUP_FILE"
[[ -s "$tmp_dump" ]] || fail "Decrypted backup is empty"

# Listing the custom archive validates that pg_restore can parse its structure
# without applying any database change.
pg_restore --list "$tmp_dump" >/dev/null
log "Decryption and PostgreSQL archive structure: OK"
log "Backup verification passed without modifying a database"
