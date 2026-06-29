# Install kura on PATH (Windows). Run from repo root:
#   .\scripts\install-kura.ps1
$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$BinDir = Join-Path $env:USERPROFILE ".local\bin"
$Target = Join-Path $BinDir "kura.exe"

$Candidates = @(
    (Join-Path $RepoRoot "target\release\kura.exe"),
    (Join-Path $RepoRoot "bin\kura.exe")
)

$Source = $Candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $Source) {
    Write-Host "Building kura..."
    Push-Location $RepoRoot
    cargo build --release
    Pop-Location
    $Source = Join-Path $RepoRoot "target\release\kura.exe"
    if (-not (Test-Path $Source)) {
        throw "Build failed: $Source not found"
    }
}

New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
Copy-Item -Force $Source $Target
Write-Host "installed kura -> $Target"

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$BinDir*") {
    $NewPath = if ($UserPath) { "$UserPath;$BinDir" } else { $BinDir }
    [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
    $env:Path = "$env:Path;$BinDir"
    Write-Host "added $BinDir to user PATH (restart shell for full effect)"
}

& $Target --version
Write-Host "Done. Run: kura compile"
