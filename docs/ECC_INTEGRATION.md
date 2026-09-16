# ECC governed integration

## Status

Mission Control integrates ECC as a governed external harness dependency. ECC does not replace PEFY Mission Control, PEFY ΩEXPERT SKILL FABRIC, ΩCODEX SECURITY FABRIC, ΩOmniRoute, or other PEFY-owned control planes.

## Pinned upstream

- Repository: `https://github.com/affaan-m/ECC`
- npm package: `ecc-universal`
- CLI binary: `ecc`
- Pinned ECC release: `2.2.1`
- ECC Git tag: `v2.2.1`
- Signed ECC tag object: `373e7ea11a62f70496d10f09693e046673ec06fd`
- Tagged ECC commit: `5064474d4d762dc9640234a41617cccb79185cec`
- ECC license: MIT
- Codex version used by isolated qualification: `@openai/codex@0.154.0`

Do not install an unrelated or stale npm package merely named `ecc`. The upstream release contract uses `ecc-universal` and exposes the `ecc` CLI.

## Required Codex installation layers

Both layers are required before a Codex workstation/runtime can be called ECC-installed and activated.

1. **Global ECC CLI layer**
   - installs `ecc-universal@2.2.1` globally;
   - verifies that the `ecc` command is on `PATH`;
   - verifies that the installed package version is exactly `2.2.1`;
   - runs `ecc doctor`.

2. **Native Codex plugin layer**
   - requires a Codex CLI that supports `codex plugin`;
   - registers the ECC marketplace from `affaan-m/ECC` with the explicit Git ref `v2.2.1`;
   - installs or refreshes `ecc@ecc` using Codex's native plugin lifecycle;
   - requires Codex JSON inventory to report the ECC plugin as installed and enabled at version `2.2.1`.

The native Codex path is implemented by `scripts/pefy-ecc-codex-native.sh`. The generic ECC command `ecc install --target codex` is retained only as a compatibility fallback when native Codex is unavailable and `ECC_REQUIRE_NATIVE_CODEX` is not set. That fallback does **not** qualify a persistent Codex host as natively activated.

Codex hook trust is a separate provider-controlled security decision. PEFY automation does not bypass or silently grant hook trust. A host can therefore be classified as ECC plugin installed/enabled while individual provider-specific hook trust remains subject to Codex's explicit trust controls.

## Operator interface

Use the PEFY wrapper:

```bash
bash scripts/pefy-ecc install
bash scripts/pefy-ecc status
bash scripts/pefy-ecc doctor
bash scripts/pefy-ecc list
bash scripts/pefy-ecc version
```

`install` is fail-closed for Codex: it requires native Codex plugin activation. `status` verifies the exact global ECC version and requires the native `ecc@ecc` Codex plugin to be installed and enabled.

The underlying scripts remain available for governed automation:

```bash
ECC_REQUIRE_NATIVE_CODEX=1 bash scripts/pefy-ecc-install.sh
bash scripts/pefy-ecc-status.sh
```

## Qualification

`.github/workflows/ecc-qualification.yml` executes the native dual-layer path in an isolated GitHub Actions runner. The workflow records npm provenance for `ecc-universal@2.2.1` and `@openai/codex@0.154.0`, installs the pinned Codex CLI, validates the native plugin interface, installs both ECC layers, checks that `ecc@ecc` is installed and enabled at version `2.2.1`, and runs ECC diagnostics/status verification.

A green qualification workflow proves that this pinned combination works in that isolated runner. It does **not** prove that a separate production host, developer workstation, or sovereign runtime has already been modified.

## Persistent host activation

Persistent activation is separated from ephemeral CI qualification.

For auditable remote activation, register an authorized Linux GitHub Actions self-hosted runner with the label `pefy-ecc`, then invoke `.github/workflows/ecc-host-activation.yml` using either:

- `status` to inspect the host without changing ECC; or
- `install` to apply the pinned native dual-layer installation and immediately re-run qualification.

For a Codex target, the self-hosted workflow requires the Codex CLI and native plugin interface before mutation and never silently falls back to generic compatibility mode.

The self-hosted runner must be a dedicated PEFY-controlled execution surface. Do not attach the `pefy-ecc` label to a shared or untrusted runner. Repository permissions are read-only in the activation workflow, and the workflow checks out trusted `master`.

A successful self-hosted `install` run is the evidence required to classify that specific persistent host as ECC-installed and host-qualified. A successful GitHub-hosted qualification run alone is not sufficient for that claim.

## Promotion policy

ECC remains subordinate to PEFY governance. Promotion beyond controlled qualification requires the normal PEFY supply-chain controls: provenance and license review, security scanning, sandboxing, version pinning, rollback readiness, capability deduplication, and operational evidence. Upstream updates must not be auto-promoted solely because a newer version exists.
