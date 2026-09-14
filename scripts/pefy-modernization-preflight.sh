#!/usr/bin/env bash
set -euo pipefail

# PEFY provider-neutral preflight for DevSwarm and code-modernization workspaces.
# This script is intentionally non-destructive. It validates prerequisites and
# policy evidence; it never mutates credentials, remotes, branches or production data.

ROOT_DIR="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
PEFY_REQUIRE_DEVSWARM="${PEFY_REQUIRE_DEVSWARM:-0}"
PEFY_DEVSWARM_APP_PATH="${PEFY_DEVSWARM_APP_PATH:-}"
PEFY_DEVSWARM_EVIDENCE_DIR="${PEFY_DEVSWARM_EVIDENCE_DIR:-$HOME/DevSwarm-PEFY-Evidence}"
PEFY_REQUIRE_CONTAINER_TOOLING="${PEFY_REQUIRE_CONTAINER_TOOLING:-0}"
PEFY_AI_COMMANDS="${PEFY_AI_COMMANDS:-claude,codex,gemini,copilot,cursor,aider,goose,opencode,amp,qwen}"

failures=0
warnings=0
assistants_found=0

pass() { printf 'PASS  %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; warnings=$((warnings + 1)); }
fail() { printf 'FAIL  %s\n' "$*"; failures=$((failures + 1)); }

require_command() {
  local command_name="$1"
  if command -v "$command_name" >/dev/null 2>&1; then
    pass "command available: ${command_name}"
  else
    fail "required command missing: ${command_name}"
  fi
}

optional_command() {
  local command_name="$1"
  if command -v "$command_name" >/dev/null 2>&1; then
    pass "optional command available: ${command_name}"
  else
    warn "optional command missing: ${command_name}"
  fi
}

is_catalogued_assistant() {
  case "$1" in
    claude|codex|gemini|copilot|cursor|aider|goose|opencode|amp|qwen) return 0 ;;
    *) return 1 ;;
  esac
}

probe_catalogued_assistant() {
  local command_name="$1"
  if ! is_catalogued_assistant "$command_name"; then
    warn "unregistered assistant command ignored for activation: ${command_name}; add it through reviewed catalogue qualification first"
    return 1
  fi
  if ! command -v "$command_name" >/dev/null 2>&1; then
    return 1
  fi
  if "$command_name" --version >/dev/null 2>&1; then
    pass "catalogued AI assistant health probe passed: ${command_name} --version"
    return 0
  fi
  warn "assistant executable exists but health/version probe failed: ${command_name}"
  return 1
}

printf 'PEFY Code Modernization / DevSwarm Preflight\n'
printf 'repository=%s\n' "$ROOT_DIR"
os_name="$(uname -s 2>/dev/null || printf unknown)"
arch_name="$(uname -m 2>/dev/null || printf unknown)"
printf 'os=%s\n' "$os_name"
printf 'arch=%s\n' "$arch_name"

require_command git
require_command bash

if [ ! -d "$ROOT_DIR/.git" ] && ! git -C "$ROOT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  fail "target is not a Git repository: ${ROOT_DIR}"
else
  pass "Git repository detected"
fi

for policy_file in \
  AGENTS.md \
  CLAUDE.md \
  GEMINI.md \
  .github/copilot-instructions.md \
  .cursor/rules/pefy-engineering.mdc; do
  if [ -f "$ROOT_DIR/$policy_file" ]; then
    pass "AI policy adapter present: ${policy_file}"
  else
    fail "AI policy adapter missing: ${policy_file}"
  fi
done

# Only reviewed/catalogued assistants may satisfy the activation requirement.
# PEFY_AI_COMMANDS can narrow the checked set, but arbitrary names do not become trusted.
IFS=',' read -r -a ai_commands <<< "$PEFY_AI_COMMANDS"
for ai_command in "${ai_commands[@]}"; do
  ai_command="${ai_command//[[:space:]]/}"
  [ -n "$ai_command" ] || continue
  if probe_catalogued_assistant "$ai_command"; then
    assistants_found=$((assistants_found + 1))
  fi
done

if [ "$assistants_found" -eq 0 ]; then
  fail "no catalogued AI assistant passed a health/version probe; install/configure at least one reviewed DevSwarm-supported CLI"
else
  pass "assistant availability satisfied (${assistants_found} verified)"
fi

# Do not guess private DevSwarm application-data locations or authentication state.
# Installation evidence is platform-backed and must be accompanied by the installer
# evidence pack produced before first launch.
devswarm_detected_path=""
if [ -n "$PEFY_DEVSWARM_APP_PATH" ]; then
  if [ -e "$PEFY_DEVSWARM_APP_PATH" ]; then
    devswarm_detected_path="$PEFY_DEVSWARM_APP_PATH"
  else
    fail "PEFY_DEVSWARM_APP_PATH does not exist: $PEFY_DEVSWARM_APP_PATH"
  fi
elif [ "$os_name" = "Darwin" ]; then
  for candidate in "/Applications/DevSwarm.app" "$HOME/Applications/DevSwarm.app"; do
    if [ -d "$candidate" ]; then
      devswarm_detected_path="$candidate"
      break
    fi
  done
fi

if [ -n "$devswarm_detected_path" ]; then
  pass "DevSwarm application detected: $devswarm_detected_path"
else
  if [ "$PEFY_REQUIRE_DEVSWARM" = "1" ]; then
    fail "DevSwarm application evidence unavailable; install the signed application or set PEFY_DEVSWARM_APP_PATH to its verified installed path"
  else
    warn "DevSwarm application not verified in this environment; set PEFY_DEVSWARM_APP_PATH when workstation evidence is required"
  fi
fi

if [ "$PEFY_REQUIRE_DEVSWARM" = "1" ]; then
  installer_env="$PEFY_DEVSWARM_EVIDENCE_DIR/installer.env"
  if [ ! -s "$installer_env" ]; then
    fail "DevSwarm immutable installer evidence missing: $installer_env"
  else
    for key in sha256 retrieved_utc version; do
      if grep -Eq "^${key}=.+" "$installer_env"; then
        pass "DevSwarm installer evidence contains ${key}"
      else
        fail "DevSwarm installer evidence missing ${key}"
      fi
    done
    if grep -Eq '^(team_id|signer_thumbprint)=.+' "$installer_env"; then
      pass "DevSwarm signer identity evidence present"
    else
      fail "DevSwarm signer identity evidence missing"
    fi
    if [ -s "$PEFY_DEVSWARM_EVIDENCE_DIR/DevSwarm.dmg" ] || [ -s "$PEFY_DEVSWARM_EVIDENCE_DIR/DevSwarm.exe" ]; then
      pass "DevSwarm rollback installer artifact retained"
    else
      fail "DevSwarm rollback installer artifact missing; retain the verified installer for deterministic rollback"
    fi
  fi
fi

optional_command make
optional_command python3
optional_command node
optional_command npm
optional_command curl
optional_command age

if [ "$PEFY_REQUIRE_CONTAINER_TOOLING" = "1" ]; then
  require_command docker
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    pass "Docker Compose available"
  else
    fail "Docker Compose unavailable"
  fi
else
  optional_command docker
fi

current_branch="$(git -C "$ROOT_DIR" branch --show-current 2>/dev/null || true)"
if [ "$current_branch" = "master" ] || [ "$current_branch" = "main" ]; then
  warn "currently on primary branch '${current_branch}'; create an isolated worktree/branch before implementation"
else
  pass "implementation branch is isolated: ${current_branch:-detached-or-unknown}"
fi

if [ -n "$(git -C "$ROOT_DIR" status --porcelain 2>/dev/null || true)" ]; then
  warn "working tree is not clean; commit/stash unrelated work before creating DevSwarm workspaces"
else
  pass "working tree is clean"
fi

printf 'summary failures=%s warnings=%s assistants=%s\n' "$failures" "$warnings" "$assistants_found"

if [ "$failures" -ne 0 ]; then
  exit 2
fi
