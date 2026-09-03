# Zyphor Release Packaging Script
$ErrorActionPreference = "Stop"

Write-Host ">>> Compiling Zyphor in ReleaseFast mode..." -ForegroundColor Cyan
zig build -Doptimize=ReleaseFast --summary all

$outDir = "dist"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Copy-Item "zig-out/bin/zyphor.exe" "$outDir/zyphor.exe" -Force
Write-Host ">>> Release binary packaged into $outDir/zyphor.exe" -ForegroundColor Green
