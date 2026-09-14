# PEFY DevSwarm Installer Verification

## Scope

This procedure verifies the proprietary DevSwarm workstation installer before first PEFY use. It does not claim that DevSwarm is open source or PEFY-owned.

PEFY evaluation baseline: **DevSwarm v2.5.0**.

Official distribution endpoints currently exposed by the DevSwarm download channel:

- macOS ARM64: `https://downloads.devswarm.ai/darwin/arm64/DevSwarm.dmg`
- Windows x64: `https://downloads.devswarm.ai/win32/x64/DevSwarm.exe`

The public GitHub v2.5.0 release contains release metadata but no proprietary application binary assets. The installer therefore comes from the official DevSwarm distribution domain, not from the GitHub source archive.

## Critical verification rule

A locally calculated SHA-256 proves that the file retained in an evidence run did not change after capture; it does **not** establish publisher authenticity unless compared with an independently published trusted checksum. Because no such public checksum was verified for this baseline, PEFY additionally requires platform publisher-signature validation and records signer information.

Do not use `curl | sh`, do not disable Gatekeeper/SmartScreen, and never bypass an invalid, missing or unexpected signature/version.

## Automated PEFY verification/installers

Preferred commands from this repository:

### macOS ARM64

```bash
bash scripts/install-devswarm-macos.sh
```

The script downloads the DMG over HTTPS, records SHA-256, verifies the disk image with Gatekeeper, mounts read-only, validates `DevSwarm.app` with `codesign` and `spctl`, requires the expected version, optionally enforces an approved Apple TeamIdentifier, copies the verified app into the configured install directory, and re-verifies the installed copy.

Optional strong pins:

```bash
PEFY_DEVSWARM_EXPECTED_VERSION=2.5.0 \
PEFY_DEVSWARM_EXPECTED_SHA256='<approved-sha256>' \
PEFY_DEVSWARM_EXPECTED_TEAM_ID='<approved-team-id>' \
PEFY_DEVSWARM_LAUNCH=1 \
  bash scripts/install-devswarm-macos.sh
```

### Windows 11 x64

```powershell
.\scripts\install-devswarm-windows.ps1
```

The PowerShell installer records SHA-256, verifies Authenticode, requires a signer certificate and expected version, optionally enforces an approved signer thumbprint, and only then starts the signed installer.

Optional strong pins:

```powershell
$env:PEFY_DEVSWARM_EXPECTED_VERSION = '2.5.0'
$env:PEFY_DEVSWARM_EXPECTED_SHA256 = '<approved-sha256>'
$env:PEFY_DEVSWARM_EXPECTED_SIGNER_THUMBPRINT = '<approved-thumbprint>'
$env:PEFY_DEVSWARM_LAUNCH = '1'
.\scripts\install-devswarm-windows.ps1
```

## Manual verification equivalents

### macOS ARM64

Minimum baseline requirements include Apple M1 or later and macOS 14 or later.

```bash
mkdir -p "$HOME/Downloads/pefy-devswarm"
cd "$HOME/Downloads/pefy-devswarm"
curl --fail --location --proto '=https' --tlsv1.2 \
  --output DevSwarm.dmg \
  'https://downloads.devswarm.ai/darwin/arm64/DevSwarm.dmg'
shasum -a 256 DevSwarm.dmg | tee DevSwarm.dmg.sha256
spctl --assess --type open --context context:primary-signature --verbose=4 DevSwarm.dmg
```

After installing the application normally:

```bash
codesign --verify --deep --strict --verbose=2 /Applications/DevSwarm.app
codesign -dv --verbose=4 /Applications/DevSwarm.app 2>&1 | tee DevSwarm.codesign.txt
spctl --assess --type execute --verbose=4 /Applications/DevSwarm.app 2>&1 | tee DevSwarm.gatekeeper.txt
```

A failed signature or Gatekeeper assessment is a hard stop.

### Windows 11 x64

```powershell
$dir = Join-Path $HOME 'Downloads\pefy-devswarm'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$installer = Join-Path $dir 'DevSwarm.exe'
Invoke-WebRequest -Uri 'https://downloads.devswarm.ai/win32/x64/DevSwarm.exe' -OutFile $installer
Get-FileHash $installer -Algorithm SHA256 | Format-List
$sig = Get-AuthenticodeSignature $installer
$sig | Format-List Status,StatusMessage,SignerCertificate,TimeStamperCertificate
if ($sig.Status -ne 'Valid') { throw "DevSwarm installer signature is not valid: $($sig.Status)" }
Start-Process -FilePath $installer -Wait
```

Record the signer certificate subject/thumbprint and timestamp. An unexpected signer change requires re-review.

## Activation evidence

After installation, launch DevSwarm and complete sign-in interactively. Review OAuth permissions, add the repository and configure its source branch. PEFY does not automate identity credentials.

On native macOS:

```bash
cd /path/to/openclaw-mission-control
PEFY_REQUIRE_DEVSWARM=1 bash scripts/pefy-modernization-preflight.sh
```

For a nonstandard path, Windows control shell or WSL/Linux repository environment, pass explicit application evidence:

```bash
PEFY_REQUIRE_DEVSWARM=1 \
PEFY_DEVSWARM_APP_PATH='/verified/path/to/DevSwarm-or-DevSwarm.app' \
  bash scripts/pefy-modernization-preflight.sh /path/to/openclaw-mission-control
```

The path is environment-specific; PEFY intentionally does not guess an undocumented DevSwarm private-data directory.

## Workstation evidence to retain

Retain only non-secret evidence:

- DevSwarm detected/approved version;
- installer URL and retrieval date;
- locally calculated SHA-256;
- installer/application signature result;
- signer certificate identity/thumbprint or macOS signing/team identity;
- OS version and architecture;
- PEFY preflight result;
- enabled AI assistant names only, never tokens/API keys;
- repository and source/default branch;
- acceptance/rejection decision and reviewer.

Do not retain OAuth tokens, API keys, environment-variable values, private code excerpts, user profiles or production response bodies in the evidence pack.

## Upgrade and rollback rule

For any DevSwarm version later than v2.5.0:

1. verify canonical release metadata and release notes;
2. review security/compatibility changes;
3. repeat download/signature/hash evidence;
4. test a disposable repository/worktree first;
5. validate assistant discovery, branch/worktree behavior, port handling and Review Mode;
6. verify PEFY instruction adapters are still honored;
7. re-run Code Modernization Fabric and repository CI gates;
8. retain the previously approved installer/version or documented uninstall/reinstall procedure as rollback evidence;
9. promote only after explicit PEFY acceptance.
