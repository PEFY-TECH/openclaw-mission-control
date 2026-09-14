# PEFY DevSwarm Installer Verification

## Scope

This procedure verifies the proprietary DevSwarm workstation installer before first PEFY use. It does not claim that DevSwarm is open source or PEFY-owned.

PEFY evaluation baseline: **DevSwarm v2.5.0**.

Official distribution endpoints currently exposed by the DevSwarm download page:

- macOS ARM64: `https://downloads.devswarm.ai/darwin/arm64/DevSwarm.dmg`
- Windows x64: `https://downloads.devswarm.ai/win32/x64/DevSwarm.exe`

The public GitHub v2.5.0 release contains release metadata but no application binary assets. The installer therefore comes from the official DevSwarm distribution domain, not from the public GitHub source archive.

## Critical rule

A locally calculated SHA-256 proves that the file used during an evidence run did not change after capture; it does **not** establish publisher authenticity unless compared with an independently published trusted checksum. Because no public checksum was verified during this baseline review, PEFY must also require platform publisher-signature validation and record the signer information.

Do not use `curl | sh`, do not disable Gatekeeper/SmartScreen, and do not bypass an invalid or missing signature.

## macOS ARM64

Minimum DevSwarm requirements include Apple M1 or later, 16 GB RAM and macOS 14 or later.

Download to a controlled staging directory:

```bash
mkdir -p "$HOME/Downloads/pefy-devswarm"
cd "$HOME/Downloads/pefy-devswarm"
curl --fail --location --proto '=https' --tlsv1.2 \
  --output DevSwarm.dmg \
  'https://downloads.devswarm.ai/darwin/arm64/DevSwarm.dmg'
```

Capture integrity evidence:

```bash
shasum -a 256 DevSwarm.dmg | tee DevSwarm.dmg.sha256
stat -f 'size=%z bytes modified=%Sm' DevSwarm.dmg
```

Install using the normal macOS UI. Do not disable Gatekeeper. After the application is installed, verify the application bundle before first PEFY use:

```bash
codesign --verify --deep --strict --verbose=2 /Applications/DevSwarm.app
codesign -dv --verbose=4 /Applications/DevSwarm.app 2>&1 | tee DevSwarm.codesign.txt
spctl --assess --type execute --verbose=4 /Applications/DevSwarm.app 2>&1 | tee DevSwarm.gatekeeper.txt
```

Promotion requirement: `codesign` verification must succeed and Gatekeeper assessment must accept the installed application. Record the signer/team information from `codesign -dv` in the workstation evidence dossier. A failed assessment is a hard stop.

Then launch DevSwarm normally, sign in, add the repository, and run:

```bash
cd /path/to/openclaw-mission-control
PEFY_REQUIRE_DEVSWARM=1 bash scripts/pefy-modernization-preflight.sh
```

## Windows 11 x64

Minimum DevSwarm requirements include Windows 11 and 16 GB RAM.

Download from PowerShell:

```powershell
$dir = Join-Path $HOME 'Downloads\pefy-devswarm'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$installer = Join-Path $dir 'DevSwarm.exe'
Invoke-WebRequest `
  -Uri 'https://downloads.devswarm.ai/win32/x64/DevSwarm.exe' `
  -OutFile $installer
```

Capture integrity evidence:

```powershell
Get-FileHash $installer -Algorithm SHA256 | Format-List | Out-File "$installer.sha256.txt"
Get-Item $installer | Select-Object FullName,Length,LastWriteTime | Format-List
```

Validate Authenticode before launch:

```powershell
$sig = Get-AuthenticodeSignature $installer
$sig | Format-List Status,StatusMessage,SignerCertificate,TimeStamperCertificate
if ($sig.Status -ne 'Valid') { throw "DevSwarm installer signature is not valid: $($sig.Status)" }
```

Record the signer certificate subject/thumbprint and timestamp details in the workstation evidence dossier. Compare the signer identity with the previously approved PEFY baseline; an unexpected signer change requires re-review.

Only after signature validation:

```powershell
Start-Process -FilePath $installer -Wait
```

If the repository is in WSL, run the PEFY preflight from that distribution after DevSwarm has been launched and initialized:

```bash
cd /path/to/openclaw-mission-control
PEFY_REQUIRE_DEVSWARM=1 bash scripts/pefy-modernization-preflight.sh
```

## Workstation evidence to retain

Retain only non-secret evidence:

- DevSwarm version displayed by the installed product;
- installer URL and retrieval date;
- SHA-256 calculated locally;
- installer/application signature validation result;
- signer certificate identity/thumbprint or macOS signing/team identity;
- OS version and architecture;
- PEFY preflight result;
- list of enabled AI assistant *names* (never API keys/tokens);
- repository and default branch used;
- acceptance/rejection decision and reviewer.

Do not retain OAuth tokens, API keys, environment-variable values, private code excerpts, user profiles or production response bodies in this evidence pack.

## Upgrade rule

For any DevSwarm version later than v2.5.0:

1. verify the canonical release announcement/version;
2. review release notes and security changes;
3. repeat download/signature/hash evidence;
4. test one disposable repository/worktree first;
5. validate assistant discovery, branch isolation, port handling and Review Mode;
6. verify PEFY instruction adapters are still honored;
7. re-run the PEFY modernization and repository CI gates;
8. record rollback to the previously approved installer/version before promotion.
