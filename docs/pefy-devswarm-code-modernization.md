# PEFY DevSwarm + Code Modernization Operating Model

## Purpose

DevSwarm is integrated as an optional workstation-level AI Development Environment (ADE) for parallel, isolated coding work. It does not replace PEFY governance, Mission Control, ClawTeam, OpenClaw, CI, security qualification or release approval.

The PEFY Code Modernization Fabric provides one provider-neutral contract for DevSwarm and other coding assistants. The same repository rules apply whether a task is executed by Codex, Claude Code, Gemini CLI, GitHub Copilot, Cursor, Aider, Goose, Amazon Q, Rovo, OpenCode or another supported assistant.

## DevSwarm qualification decision

Official DevSwarm documentation states that the product is a proprietary desktop application. Its public GitHub repository is the landing page and issue tracker, not the application source. Therefore PEFY must not fork, vendor, rebrand or absorb the application. DevSwarm is used behind a PEFY-owned adapter and remains replaceable.

DevSwarm's useful capabilities for this architecture are:

- isolated Git worktree per workspace;
- parallel AI assistants on independent branches;
- unique port assignments per workspace;
- GitHub/Jira integrations;
- Review Mode for branch diffs;
- multiple assistants in the same workspace;
- HiveControl for AI-directed workspace orchestration;
- local-first code handling with user-owned assistant credentials.

## Supported workstation model

DevSwarm currently targets macOS and Windows, with WSL repository support on Windows. Git must be available in `PATH`, and at least one supported CLI coding assistant must be installed. The application is installed from the official DevSwarm download page and requires user sign-in.

### macOS prerequisite example

```bash
# Verify prerequisites
xcode-select -p || xcode-select --install
git --version

# Optional Homebrew Git if your workstation policy permits Homebrew
brew install git

# Open the official installer page
open https://devswarm.ai/download
```

After installation and first launch:

```bash
cd /path/to/openclaw-mission-control
bash scripts/pefy-modernization-preflight.sh
```

To require evidence that DevSwarm has been initialized for the current user:

```bash
PEFY_REQUIRE_DEVSWARM=1 bash scripts/pefy-modernization-preflight.sh
```

### Windows 11 / PowerShell prerequisite example

```powershell
# Git
winget install --id Git.Git -e

git --version

# Optional WSL if your repositories are hosted in Linux filesystems
wsl --install -d Ubuntu
wsl --status

# Open the official installer page
Start-Process 'https://devswarm.ai/download'
```

For a WSL-hosted repository, run the PEFY preflight inside the distribution:

```bash
cd /path/to/openclaw-mission-control
bash scripts/pefy-modernization-preflight.sh
```

Keep repositories in their native environment where practical; cross-boundary Windows/WSL filesystem access can reduce performance.

## Repository onboarding in DevSwarm

1. Install and launch DevSwarm from the official distribution.
2. Sign in with the approved Google or GitHub identity.
3. Connect GitHub through DevSwarm OAuth only after reviewing requested permissions.
4. Add or clone the repository.
5. Set the correct source/default branch (`master` for Mission Control unless the repository is intentionally rebaselined).
6. Confirm the primary workspace is clean.
7. Run `scripts/pefy-modernization-preflight.sh`.
8. Confirm at least one assistant is detected.
9. Create implementation workspaces from a feature branch, PR or ticket; do not use the primary branch as an implementation workspace.
10. Review diffs and CI before merge.

## Multi-AI instruction adapters

The repository contains a canonical contract plus discovery adapters:

- `AGENTS.md` — canonical provider-neutral contract.
- `CLAUDE.md` — Claude Code adapter.
- `GEMINI.md` — Gemini CLI adapter.
- `.github/copilot-instructions.md` — GitHub Copilot adapter.
- `.cursor/rules/pefy-engineering.mdc` — Cursor project rule.

Assistants that understand `AGENTS.md` use it directly. Other tools receive an adapter that points back to the same policy. Provider-specific files must not weaken the canonical contract.

## DevSwarm execution patterns

### Parallel implementation pattern

Use separate workspaces for independent slices, for example:

- Workspace A — backend behavior;
- Workspace B — frontend/UI;
- Workspace C — tests and negative paths;
- Workspace D — documentation/migration notes;
- Workspace E — independent review/security challenge.

Merge only after each slice is rebased/reconciled against the current source branch and the combined result passes repository CI.

### Same-task comparative pattern

For difficult refactors, give the same bounded task to two different assistants in separate workspaces. Compare diffs, tests, complexity, security and maintainability. Select or synthesize the best evidence-backed implementation; never merge both blindly.

### HiveControl pattern

Inside a DevSwarm workspace, a supported assistant can be asked to orchestrate parallel child workspaces. Use a bounded instruction such as:

```text
Hey DevSwarm, plan this change into independently testable workstreams. Create only the minimum parallel workspaces required. Every child must follow AGENTS.md, remain on an isolated branch, run its relevant tests, and return a concise diff/evidence summary. Do not merge. Escalate security-sensitive, destructive, credential, migration, or production actions for human/PEFY approval.
```

HiveControl is an execution mechanism, not a release authority.

## Code modernization pipeline

Every modernization task follows this sequence:

1. Discovery — identify language/runtime/framework/toolchain and current versions.
2. Inventory — dependency graph, APIs, generated code, migrations, plugins, deployment/runtime surfaces.
3. Provenance/licence — verify canonical source, version/tag/SHA, SPDX/licence obligations and notices.
4. Baseline — tests, build, lint/typecheck, coverage, current vulnerabilities, performance/reliability where relevant.
5. Classify — dependency remediation, runtime/framework upgrade, API migration, architecture refactor, security hardening, observability, test or DX modernization.
6. Plan — incremental/reversible slices, compatibility constraints and rollback.
7. Implement in isolated worktree(s).
8. Security — SAST/SCA/secrets/SBOM as applicable; prove negative paths for sensitive controls.
9. Validate — targeted tests then full CI/build/E2E/installer gates as applicable.
10. Compare — before/after behavior, risk, performance and operational impact.
11. Review — independent human/agent review and finding closure.
12. PR — immutable candidate SHA and evidence.
13. Runtime qualification — real host, dependencies, health/readiness, allowed/denied actions, logs.
14. Rollback/restore proof.
15. Promotion — only after objective gates pass.

## Security toolchain

The fabric supports security tools as replaceable adapters. Do not mass-install them on every workstation. Select tools by language/risk, verify provenance and pin versions in the environment that owns the scan.

Recommended capability classes include:

- SAST: Codex Security, Semgrep, CodeQL;
- SCA/advisories: package-manager audit, OSV-Scanner, Grype/Trivy;
- SBOM: Syft or equivalent CycloneDX/SPDX generator;
- secrets: Gitleaks or equivalent;
- dependency automation: Dependabot/Renovate behind review gates;
- large-scale source migration: OpenRewrite or language-native codemods;
- current library documentation: Context7;
- source/PR/CI evidence: GitHub.

High/critical runtime vulnerabilities are promotion blockers unless an explicit, time-bounded, approved risk exception exists with compensating controls.

## Codex Security plugin

Codex Security is a useful optional ChatGPT security adapter. Installation/connection occurs through the ChatGPT plugin UI and requires user action. It must remain subordinate to the PEFY security fabric and does not replace repository CI, source-level scanners, SBOM/provenance or runtime verification.

## Useful preflight parameters

```bash
# Add or replace assistant binary names without editing the script
PEFY_AI_COMMANDS='claude,codex,gemini,copilot,aider,goose,opencode,custom-agent' \
  bash scripts/pefy-modernization-preflight.sh

# Require DevSwarm initialization evidence
PEFY_REQUIRE_DEVSWARM=1 \
  bash scripts/pefy-modernization-preflight.sh

# Require Docker + Compose in addition to the base toolchain
PEFY_REQUIRE_CONTAINER_TOOLING=1 \
  bash scripts/pefy-modernization-preflight.sh

# Combine requirements
PEFY_REQUIRE_DEVSWARM=1 \
PEFY_REQUIRE_CONTAINER_TOOLING=1 \
PEFY_AI_COMMANDS='claude,codex,gemini,copilot' \
  bash scripts/pefy-modernization-preflight.sh /path/to/repository
```

Exit code `0` means required checks passed; exit code `2` means at least one required precondition failed. Warnings do not by themselves qualify or disqualify a production release.

## Production rule

Installation is never equivalent to production qualification. A DevSwarm workstation may be operational while OpenClaw, ClawTeam or Mission Control runtime qualification is still blocked. The AI Project Gallery and release evidence must preserve those separate states.
