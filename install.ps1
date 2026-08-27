# ==============================================================================
# Zyphor Universal One-Line Installer for Windows (PowerShell)
# Usage:
#   irm https://raw.githubusercontent.com/miyaniakshar1234/Zyphor/master/install.ps1 | iex
# ==============================================================================

$ErrorActionPreference = 'Stop'

$repo = "miyaniakshar1234/Zyphor"
$binary = "zyphor.exe"

Write-Host ""
Write-Host "  ◈━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◈" -ForegroundColor Cyan
Write-Host "  ┃            ZYPHOR SYSTEM OBSERVATORY              ┃" -ForegroundColor Cyan
Write-Host "  ┃         Universal Installer (Windows)             ┃" -ForegroundColor Cyan
Write-Host "  ◈━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◈" -ForegroundColor Cyan
Write-Host ""

# Detect architecture
$arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "aarch64" } else { "x86_64" }
Write-Host "==> Detecting system architecture: windows-$arch" -ForegroundColor Blue

# Fetch latest release tag
Write-Host "==> Querying latest release from GitHub ($repo)..." -ForegroundColor Blue
try {
    $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -UseBasicParsing
    $tag = $releaseInfo.tag_name
} catch {
    $tag = "v0.1.0"
    Write-Host "Warning: Could not fetch latest tag from API. Defaulting to $tag." -ForegroundColor Yellow
}

Write-Host "==> Target release version: $tag" -ForegroundColor Blue

$assetName = "zyphor-windows-$arch.zip"
$fallbackAssetName = "zyphor-windows-x86_64.zip"
$downloadUrl = "https://github.com/$repo/releases/download/$tag/$assetName"
$fallbackUrl = "https://github.com/$repo/releases/download/$tag/$fallbackAssetName"

$tmpDir = Join-Path $env:TEMP ("zyphor-install-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

$zipPath = Join-Path $tmpDir "zyphor.zip"

Write-Host "==> Downloading $downloadUrl..." -ForegroundColor Blue
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
} catch {
    Write-Host "Notice: Trying fallback asset $fallbackUrl..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $fallbackUrl -OutFile $zipPath -UseBasicParsing
}

Write-Host "==> Extracting binary payload..." -ForegroundColor Blue
Expand-Archive -Path $zipPath -DestinationPath $tmpDir -Force

$foundExe = Get-ChildItem -Path $tmpDir -Filter $binary -Recurse | Select-Object -First 1
if (-not $foundExe) {
    Write-Error "Error: $binary was not found in downloaded release package."
    exit 1
}

$installDir = Join-Path $env:LOCALAPPDATA "Zyphor\bin"
New-Item -ItemType Directory -Path $installDir -Force | Out-Null
$targetExe = Join-Path $installDir $binary

Copy-Item -Path $foundExe.FullName -Destination $targetExe -Force
Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

# Ensure installDir is in User PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -split ';' -notcontains $installDir) {
    Write-Host "==> Adding $installDir to User PATH..." -ForegroundColor Blue
    $newPath = "$installDir;$userPath"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = "$installDir;$env:Path"
}

Write-Host ""
Write-Host "✓ Successfully installed Zyphor $tag!" -ForegroundColor Green
Write-Host ""
Write-Host "Run Zyphor in any terminal with:" -ForegroundColor Cyan
Write-Host "  zyphor         # Launch Interactive Observatory TUI" -ForegroundColor White
Write-Host "  zyphor doctor  # Run System Diagnostics Audit" -ForegroundColor White
Write-Host "  zyphor bench   # Run Hardware Multi-Core Benchmark" -ForegroundColor White
Write-Host "  zyphor --help  # View CLI commands & options" -ForegroundColor White
Write-Host ""
