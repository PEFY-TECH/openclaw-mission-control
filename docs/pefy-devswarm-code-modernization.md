# PEFY DevSwarm + Code Modernization Operating Model

## Purpose

DevSwarm is integrated as an optional workstation-level AI Development Environment (ADE) for parallel, isolated coding work. It does not replace PEFY governance, Mission Control, ClawTeam, OpenClaw, CI, security qualification or release approval.

The PEFY Code Modernization Fabric exposes one provider-neutral contract to Codex, Claude Code, Gemini CLI, GitHub Copilot, Cursor, Amazon Q, Rovo, Goose, Aider, Amp, Mistral Vibe, Qwen Code, OpenCode, Cline, Plandex, Droid and future assistants.

## DevSwarm governance decision

Official DevSwarm is proprietary. Its public GitHub repository is a landing page/issue tracker and does not contain the application source. PEFY therefore does not fork, vendor, rebrand or absorb DevSwarm. It remains a replaceable workstation adapter behind PEFY-owned policy and Git boundaries.

PEFY evaluation baseline: **DevSwarm v2.5.0**. The official GitHub release was published on 2026-09-08 and identifies the original product release date as 2026-08-14. Do not auto-upgrade simply because a newer version exists; repeat provenance, signature, compatibility and rollback review first.

Useful DevSwarm capabilities include isolated Git worktrees/branches, parallel assistants, independent ports, Review Mode, GitHub/Jira integrations, multiple assistants in one workspace and HiveControl-style orchestration.

A Git worktree is **not** an OS security boundary. Sensitive work may additionally require a container, VM, sandbox, restricted account or ephemeral credentials. Never auto-copy `.env`, API keys, private keys, production dumps or private evidence into AI workspaces.

## Supported workstation model

DevSwarm currently targets macOS and Windows, including WSL repository workflows on Windows. Git must be available and at least one CLI coding assistant must be installed. DevSwarm sign-in is interactive; PEFY scripts never collect or automate the user's DevSwarm/GitHub/AI credentials.

## Verified installation

### macOS ARM64

Run the PEFY installer from the repository:

```bash
cd /path/to/openclaw-mission-control
bash scripts/install-devswarm-macos.sh
```

Default baseline parameters:

```bash
PEFY_DEVSWARM_EXPECTED_VERSION=2.5.0
PEFY_DEVSWARM_URL='https://downloads.devswarm.ai/darwin/arm64/DevSwarm.dmg'
PEFY_DEVSWARM_INSTALL_DIR='/Applications'
PEFY_DEVSWARM_LAUNCH=0
PEFY_DEVSWARM_KEEP_DOWNLOAD=0
PEFY_DEVSWARM_EVIDENCE_DIR="$HOME/DevSwarm-PEFY-Evidence"
```

Optional stronger pinning after PEFY has approved a concrete installer/signing identity:

```bash
PEFY_DEVSWARM_EXPECTED_SHA256='<approved-installer-sha256>' \
PEFY_DEVSWARM_EXPECTED_TEAM_ID='<approved-apple-team-id>' \
PEFY_DEVSWARM_LAUNCH=1 \
  bash scripts/install-devswarm-macos.sh
```

The installer validates HTTPS retrieval, local SHA-256, Gatekeeper assessment, application code signature and the expected DevSwarm version. It never disables Gatekeeper.

### Windows 11 x64

From PowerShell in the repository:

```powershell
.\scripts\install-devswarm-windows.ps1
```

Default/optional environment parameters:

```powershell
$env:PEFY_DEVSWARM_EXPECTED_VERSION = '2.5.0'
$env:PEFY_DEVSWARM_URL = 'https://downloads.devswarm.ai/win32/x64/DevSwarm.exe'
$env:PEFY_DEVSWARM_LAUNCH = '0'
$env:PEFY_DEVSWARM_KEEP_DOWNLOAD = '0'
$env:PEFY_DEVSWARM_EVIDENCE_DIR = "$HOME\DevSwarm-PEFY-Evidence"

# Optional stronger pinning after approval:
$env:PEFY_DEVSWARM_EXPECTED_SHA256 = '<approved-installer-sha256>'
$env:PEFY_DEVSWARM_EXPECTED_SIGNER_THUMBPRINT = '<approved-signing-certificate-thumbprint>'

.\scripts\install-devswarm-windows.ps1
```

The PowerShell installer checks Windows 11/x64, SHA-256, Authenticode validity, signer information and expected application version before starting the installer. It never disables SmartScreen or accepts an invalid signature.

See `docs/pefy-devswarm-installer-verification.md` for the evidence model and upgrade procedure.

## Activation and repository onboarding

Installation is followed by an explicit, human-controlled activation sequence:

1. Launch the signed DevSwarm application.
2. Sign in with the approved Google or GitHub identity.
3. Review OAuth permissions before authorizing GitHub/Jira or other integrations.
4. Add or clone the repository.
5. Set the correct source/default branch (`master` for Mission Control unless intentionally changed).
6. Confirm the source working tree is clean.
7. Confirm at least one supported assistant is installed and authenticated through its own provider mechanism.
8. Run the PEFY preflight.
9. Create implementation workspaces on feature branches/worktrees, never directly on the primary branch.
10. Review diffs and CI before merge.

### Native macOS preflight

The preflight can detect `/Applications/DevSwarm.app` automatically:

```bash
cd /path/to/openclaw-mission-control
PEFY_REQUIRE_DEVSWARM=1 \
  bash scripts/pefy-modernization-preflight.sh
```

### Explicit application evidence

For a nonstandard installation location, Windows Git-Bash environment, WSL or another control shell, provide the verified application path explicitly:

```bash
PEFY_REQUIRE_DEVSWARM=1 \
PEFY_DEVSWARM_APP_PATH='/verified/path/to/DevSwarm-or-DevSwarm.app' \
  bash scripts/pefy-modernization-preflight.sh /path/to/repository
```

PEFY intentionally does **not** infer activation from an undocumented `~/.devswarm` or other guessed private data directory.

### Additional preflight parameters

```bash
# Override/extend assistant binary discovery without editing the script.
PEFY_AI_COMMANDS='claude,codex,gemini,copilot,aider,goose,opencode,custom-agent' \
  bash scripts/pefy-modernization-preflight.sh

# Require Docker and Compose for workloads that need container isolation.
PEFY_REQUIRE_CONTAINER_TOOLING=1 \
  bash scripts/pefy-modernization-preflight.sh

# Combine all required evidence.
PEFY_REQUIRE_DEVSWARM=1 \
PEFY_DEVSWARM_APP_PATH='/verified/path/to/DevSwarm' \
PEFY_REQUIRE_CONTAINER_TOOLING=1 \
PEFY_AI_COMMANDS='claude,codex,gemini,copilot' \
  bash scripts/pefy-modernization-preflight.sh /path/to/repository
```

Exit code `0` means required preconditions passed; exit code `2` means one or more required preconditions failed. Warnings are informational and do not constitute release qualification.

## Multi-AI instruction adapters

The repository contains one canonical contract plus discovery adapters:

- `AGENTS.md` — canonical provider-neutral contract;
- `CLAUDE.md` — Claude Code adapter;
- `GEMINI.md` — Gemini CLI adapter;
- `.github/copilot-instructions.md` — GitHub Copilot adapter;
- `.cursor/rules/pefy-engineering.mdc` — Cursor project rule.

Provider-specific files may add discovery syntax but may never create a weaker policy path than `AGENTS.md`.

## DevSwarm execution patterns

### Parallel slices

Use independent workspaces for separable work, for example backend, frontend, tests/negative paths, documentation/migrations and independent security review. Reconcile branches before merge and run the combined CI.

### Comparative implementation

For a difficult refactor, assign the same bounded task to two different assistants in separate workspaces. Compare correctness, tests, complexity, security and maintainability, then select or synthesize the best evidence-backed implementation. Never merge both blindly.

### HiveControl-style orchestration

Use a bounded orchestration instruction such as:

```text
Hey DevSwarm, split this change into the minimum independently testable workstreams. Every child workspace must follow AGENTS.md, remain on an isolated branch, run its relevant tests and return a concise diff/evidence summary. Do not merge. Escalate destructive, credential, migration, security-sensitive or production actions for PEFY/human approval.
```

Workspace orchestration is an execution mechanism, not a release authority.

## Code modernization pipeline

Every modernization task follows the governed sequence:

1. discovery of language/runtime/framework/toolchain;
2. inventory of dependencies, APIs, generated code, migrations, plugins and deployment surfaces;
3. canonical provenance and licence verification;
4. baseline tests/build/lint/typecheck/coverage/vulnerability evidence;
5. change classification and reversible migration plan;
6. isolated implementation;
7. SAST/SCA/secrets/SBOM controls as applicable;
8. unit/integration/build/E2E and negative-path validation;
9. before/after performance/reliability evidence where relevant;
10. independent review and finding closure;
11. PR with immutable candidate SHA;
12. CI and supply-chain gates;
13. real-host runtime qualification where applicable;
14. rollback/restore proof;
15. controlled promotion.

Modernization is evidence-driven, not version-chasing.

## Security toolchain

Use tools as replaceable adapters selected by project risk; do not mass-install them merely to increase tool count. Capability classes include Codex Security/Semgrep/CodeQL for SAST, package-manager audit/OSV/Grype/Trivy for SCA, Syft/CycloneDX/SPDX for SBOM, Gitleaks for secrets, Dependabot/Renovate for reviewed dependency automation, and OpenRewrite/language-native codemods for large migrations.

Codex Security is an optional ChatGPT plugin. Installation requires the user's plugin-UI action and remains subordinate to PEFY security, CI, provenance and runtime evidence.

## Production rule

**Installation is never production qualification.** A signed and functioning DevSwarm workstation can be operational while Mission Control, ClawTeam or OpenClaw remains blocked at a separate code/runtime/live-production gate. Those assurance states must remain distinct.
