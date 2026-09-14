$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# PEFY verified installer for the approved DevSwarm workstation baseline.
# Supported target: Windows 11 x64. This script never disables SmartScreen or
# signature verification and never handles DevSwarm/GitHub/AI credentials.

$Url = if ($env:PEFY_DEVSWARM_URL) { $env:PEFY_DEVSWARM_URL } else { 'https://downloads.devswarm.ai/win32/x64/DevSwarm.exe' }
$ExpectedVersion = if ($env:PEFY_DEVSWARM_EXPECTED_VERSION) { $env:PEFY_DEVSWARM_EXPECTED_VERSION } else { '2.5.0' }
$ExpectedSha256 = if ($env:PEFY_DEVSWARM_EXPECTED_SHA256) { $env:PEFY_DEVSWARM_EXPECTED_SHA256.ToUpperInvariant() } else { '' }
$ExpectedSignerThumbprint = if ($env:PEFY_DEVSWARM_EXPECTED_SIGNER_THUMBPRINT) { ($env:PEFY_DEVSWARM_EXPECTED_SIGNER_THUMBPRINT -replace '\s','').ToUpperInvariant() } else { '' }
$LaunchAfterInstall = $env:PEFY_DEVSWARM_LAUNCH -eq '1'
$KeepDownload = $env:PEFY_DEVSWARM_KEEP_DOWNLOAD -eq '1'
$EvidenceDir = if ($env:PEFY_DEVSWARM_EVIDENCE_DIR) { $env:PEFY_DEVSWARM_EVIDENCE_DIR } else { Join-Path $HOME 'DevSwarm-PEFY-Evidence' }

function Fail([string]$Message, [int]$Code = 1) {
    Write-Error "[PEFY-DEVSWARM][FAIL] $Message"
    exit $Code
}

function Log([string]$Message) {
    Write-Host "[PEFY-DEVSWARM] $Message"
}

if (-not $IsWindows) { Fail 'This installer requires Windows.' 10 }
if (-not [Environment]::Is64BitOperatingSystem) { Fail 'PEFY DevSwarm baseline requires Windows x64.' 11 }

$os = Get-CimInstance Win32_OperatingSystem
if ([int]$os.BuildNumber -lt 22000) { Fail "Windows 11 or later is required (build=$($os.BuildNumber))." 12 }

New-Item -ItemType Directory -Force -Path $EvidenceDir | Out-Null
$WorkDir = Join-Path ([IO.Path]::GetTempPath()) ("pefy-devswarm-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
$Installer = Join-Path $WorkDir 'DevSwarm.exe'

try {
    Log 'Downloading approved DevSwarm channel over HTTPS.'
    Invoke-WebRequest -Uri $Url -OutFile $Installer -UseBasicParsing

    $hash = (Get-FileHash -Path $Installer -Algorithm SHA256).Hash.ToUpperInvariant()
    @(
        "url=$Url"
        "retrieved_utc=$([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))"
        "sha256=$hash"
    ) | Set-Content -Path (Join-Path $EvidenceDir 'installer.env') -Encoding UTF8
    $hash | Set-Content -Path (Join-Path $EvidenceDir 'DevSwarm.exe.sha256.txt') -Encoding ASCII

    if ($ExpectedSha256 -and $hash -ne $ExpectedSha256) {
        Fail 'Installer SHA-256 mismatch.' 20
    }

    $signature = Get-AuthenticodeSignature -FilePath $Installer
    $signature | Format-List Status, StatusMessage, SignerCertificate, TimeStamperCertificate | Out-File (Join-Path $EvidenceDir 'authenticode.txt') -Encoding UTF8
    if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid) {
        Fail "DevSwarm installer Authenticode signature is not valid: $($signature.Status)." 21
    }
    if (-not $signature.SignerCertificate) {
        Fail 'DevSwarm installer has no signer certificate.' 22
    }

    $thumbprint = ($signature.SignerCertificate.Thumbprint -replace '\s','').ToUpperInvariant()
    $signerSubject = $signature.SignerCertificate.Subject
    Add-Content -Path (Join-Path $EvidenceDir 'installer.env') -Value "signer_thumbprint=$thumbprint" -Encoding UTF8
    Add-Content -Path (Join-Path $EvidenceDir 'installer.env') -Value "signer_subject=$signerSubject" -Encoding UTF8

    if ($ExpectedSignerThumbprint -and $thumbprint -ne $ExpectedSignerThumbprint) {
        Fail "Unexpected DevSwarm signer certificate thumbprint: got $thumbprint." 23
    }

    $versionInfo = (Get-Item $Installer).VersionInfo
    $detectedVersion = if ($versionInfo.ProductVersion) { $versionInfo.ProductVersion } else { $versionInfo.FileVersion }
    if (-not $detectedVersion) { Fail 'Could not determine DevSwarm installer version from file metadata.' 24 }
    $escapedVersion = [regex]::Escape($ExpectedVersion)
    if ($detectedVersion -notmatch "^$escapedVersion(?:\.|$)") {
        Fail "Unexpected DevSwarm version: got '$detectedVersion', expected '$ExpectedVersion'." 25
    }
    Add-Content -Path (Join-Path $EvidenceDir 'installer.env') -Value "version=$detectedVersion" -Encoding UTF8

    Log "Signature and version verified: version=$detectedVersion signer=$signerSubject"
    Log 'Launching the signed installer interactively. Do not bypass SmartScreen or certificate warnings.'
    $process = Start-Process -FilePath $Installer -PassThru -Wait
    if ($process.ExitCode -ne 0) { Fail "DevSwarm installer exited with code $($process.ExitCode)." 26 }

    Log "Installer completed. Evidence directory: $EvidenceDir"
    Log 'Next: launch DevSwarm, sign in interactively, authorize only approved integrations, add the repository, then run the PEFY modernization preflight from the repository/WSL environment.'

    if ($LaunchAfterInstall) {
        $candidatePaths = @(
            (Join-Path $env:LOCALAPPDATA 'Programs\DevSwarm\DevSwarm.exe'),
            (Join-Path $env:ProgramFiles 'DevSwarm\DevSwarm.exe')
        )
        $app = $candidatePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($app) {
            $appSignature = Get-AuthenticodeSignature -FilePath $app
            if ($appSignature.Status -ne [System.Management.Automation.SignatureStatus]::Valid) {
                Fail "Installed DevSwarm executable signature is invalid: $($appSignature.Status)." 27
            }
            Start-Process -FilePath $app
            Log 'DevSwarm launched. Complete sign-in interactively; no credentials are handled by this script.'
        } else {
            Write-Warning 'DevSwarm executable was not found in the standard candidate paths; launch it from the Start menu and complete sign-in interactively.'
        }
    }
}
finally {
    if ($KeepDownload -and (Test-Path $Installer)) {
        Copy-Item -Path $Installer -Destination (Join-Path $EvidenceDir 'DevSwarm.exe') -Force
    }
    if (Test-Path $WorkDir) {
        Remove-Item -Path $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
