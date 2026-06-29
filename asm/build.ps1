# Build kura ASM (Windows x64)
param(
    [string]$Out = "bin/kura-asm.exe"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$AsmDir = Join-Path $Root "asm"
$BuildDir = Join-Path $AsmDir "build"
$Src = Join-Path $AsmDir "src\kura.asm"
$Obj = Join-Path $BuildDir "kura.obj"
$Tools = Join-Path $AsmDir "tools"

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $Out) | Out-Null

function Find-Nasm {
    $cmd = Get-Command nasm -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidates = @(
        "$Tools\nasm\nasm.exe",
        "C:\Program Files\NASM\nasm.exe",
        "C:\Program Files (x86)\NASM\nasm.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    New-Item -ItemType Directory -Force -Path $Tools | Out-Null
    $zip = Join-Path $Tools "nasm-win64.zip"
    if (-not (Test-Path $zip)) {
        Write-Host "Downloading NASM..."
        $url = "https://www.nasm.us/pub/nasm/releasebuilds/3.01/win64/nasm-3.01-win64.zip"
        Invoke-WebRequest -Uri $url -OutFile $zip
    }
    $dest = Join-Path $Tools "nasm"
    if (-not (Test-Path (Join-Path $dest "nasm.exe"))) {
        Expand-Archive -Path $zip -DestinationPath $dest -Force
        $inner = Get-ChildItem $dest -Directory | Select-Object -First 1
        if ($inner) {
            Get-ChildItem $inner.FullName | Move-Item -Destination $dest -Force
        }
    }
    return (Join-Path $dest "nasm.exe")
}

function Find-GoLink {
    $cmd = Get-Command golink -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $path = Join-Path $Tools "GoLink.exe"
    if (Test-Path $path) { return $path }
    New-Item -ItemType Directory -Force -Path $Tools | Out-Null
    $zip = Join-Path $Tools "Golink.zip"
    if (-not (Test-Path $zip)) {
        Write-Host "Downloading GoLink..."
        $urls = @(
            "http://www.godevtool.com/Golink.zip",
            "https://www.godevtool.com/Golink.zip"
        )
        foreach ($url in $urls) {
            try {
                Invoke-WebRequest -Uri $url -OutFile $zip
                break
            } catch {
                Write-Host "Failed: $url"
            }
        }
    }
    if (-not (Test-Path $path)) {
        Expand-Archive -Path $zip -DestinationPath $Tools -Force
    }
    if (-not (Test-Path $path)) {
        throw "GoLink.exe not found after extract"
    }
    return $path
}

$nasm = Find-Nasm
$golink = Find-GoLink
Write-Host "NASM: $nasm"
Write-Host "GoLink: $golink"

Push-Location (Join-Path $AsmDir "src")
& $nasm -f win64 -o $Obj kura.asm
Pop-Location

if ($LASTEXITCODE -ne 0) { throw "nasm failed" }

& $golink /console /entry main $Obj kernel32.dll
if ($LASTEXITCODE -ne 0) { throw "golink failed" }

$exe = Join-Path $BuildDir "kura.exe"
if (-not (Test-Path $exe)) {
    throw "expected $exe after link"
}

Copy-Item -Force $exe (Join-Path $Root $Out)
Write-Host "Built $Out"
