# Zyphor Automated Installer for Windows
$ErrorActionPreference = "Stop"

Write-Host ">>> Building Zyphor ReleaseFast binary..." -ForegroundColor Cyan
zig build -Doptimize=ReleaseFast

$binPath = Join-Path (Get-Location) "zig-out\bin\zyphor.exe"
if (Test-Path $binPath) {
    Write-Host ">>> Installation successful! Binary available at: $binPath" -ForegroundColor Green
    Write-Host ">>> Run 'zyphor doctor' to verify system readiness." -ForegroundColor Yellow
} else {
    Write-Error "Build failed: binary not found."
}
