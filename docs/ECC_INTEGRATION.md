# ECC governed integration

## Status

Mission Control integrates ECC as a governed external harness dependency. ECC does not replace PEFY Mission Control, PEFY ΩEXPERT SKILL FABRIC, ΩCODEX SECURITY FABRIC, ΩOmniRoute, or other PEFY-owned control planes.

## Pinned upstream

- Repository: `https://github.com/affaan-m/ECC`
- npm package: `ecc-universal`
- CLI binary: `ecc`
- Pinned release: `2.2.1`
- Git tag: `v2.2.1`
- Signed tag object: `373e7ea11a62f70496d10f09693e046673ec06fd`
- Tagged commit: `5064474d4d762dc9640234a41617cccb79185cec`
- License: MIT

Do not install an unrelated or stale npm package merely named `ecc`. The upstream release contract uses `ecc-universal` and exposes the `ecc` CLI.

## Required installation layers

Both layers are required for a qualified workstation/runtime:

1. **Global CLI layer**
   - installs `ecc-universal@2.2.1` globally;
   - verifies that the `ecc` command is on `PATH`;
   - verifies that the installed package version is exactly `2.2.1`.

2. **Codex harness layer**
   - previews the installation with `--dry-run`;
   - installs the `core` profile into the `codex` target;
   - runs `ecc doctor`;
   - runs `ecc list-installed` for post-install inspection.

The canonical automation is:

```bash
bash scripts/pefy-ecc-install.sh
```

Optional controlled overrides:

```bash
ECC_VERSION=2.2.1 ECC_PROFILE=core ECC_TARGET=codex \
  bash scripts/pefy-ecc-install.sh
```

## Qualification

`.github/workflows/ecc-qualification.yml` executes both installation layers in an isolated GitHub Actions runner and records npm registry provenance fields (`dist.integrity` and `dist.shasum`) before installation.

A green workflow proves that the pinned package can be retrieved, the global CLI installation succeeds, the Codex-target installation succeeds, and ECC diagnostics complete in that runner. It does **not** prove that any separate production host, developer workstation, or sovereign runtime has already been modified.

## Promotion policy

ECC remains subordinate to PEFY governance. Promotion beyond controlled qualification requires the normal PEFY supply-chain controls: provenance and license review, security scanning, sandboxing, version pinning, rollback readiness, capability deduplication, and operational evidence. Upstream updates must not be auto-promoted solely because a newer version exists.
