#!/usr/bin/env bash
set -euo pipefail

# PEFY provider-neutral preflight for DevSwarm and code-modernization workspaces.
# This script is intentionally non-destructive: it validates prerequisites and
# prints actionable state; it does not install proprietary software or mutate
# credentials, agent configuration, Git remotes, branches, or production data.

ROOT_DIR="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
PEFY_REQUIRE_DEVSWARM="${PEFY_REQUIRE_DEVSWARM:-0}"
PEFY_DEVSWARM_APP_PATH="${PEFY_DEVSWARM_APP_PATH:-}"
PEFY_REQUIRE_CONTAINER_TOOLING="${PEFY_REQUIRE_CONTAINER_TOOLING:-0}"
PEFY_AI_COMMANDS="${PEFY_AI_COMMANDS:-claude,codex,gemini,copilot,aider,goose,opencode,amp,qwen}"

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

# DevSwarm requires at least one supported assistant. The product performs its
# own discovery; this local probe only gives operators early visibility. Add
# future/custom binaries with PEFY_AI_COMMANDS=cmd1,cmd2,... without changing code.
IFS=',' read -r -a ai_commands <<< "$PEFY_AI_COMMANDS"
for ai_command in "${ai_commands[@]}"; do
  ai_command="${ai_command//[[:space:]]/}"
  [ -n "$ai_command" ] || continue
  if command -v "$ai_command" >/dev/null 2>&1; then
    pass "AI assistant CLI detected: ${ai_command}"
    assistants_found=$((assistants_found + 1))
  fi
done

if [ "$assistants_found" -eq 0 ]; then
  fail "no AI assistant CLI detected; install/configure at least one DevSwarm-supported assistant"
else
  pass "assistant availability satisfied (${assistants_found} detected)"
fi

# Do not guess DevSwarm's private application-data directory. The official
# public documentation does not establish one canonical cross-platform path.
# Require either an explicit operator-provided application path or a documented
# native macOS install location that can be verified by the OS.
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

# Guard the workspace contract. A dirty primary branch can accidentally leak
# unrelated edits into a swarm worktree or review.
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
