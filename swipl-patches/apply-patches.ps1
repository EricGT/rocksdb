# Apply vcpkg pack_install patches to SWI-Prolog
# Run as Administrator in PowerShell

param(
    [string]$SwiplPath = "C:\Program Files\swipl",
    [switch]$Restore
)

$BuildDir = Join-Path $SwiplPath "library\build"

if ($Restore) {
    Write-Host "Restoring original files..." -ForegroundColor Yellow

    if (Test-Path "$BuildDir\cmake.pl.backup") {
        Copy-Item "$BuildDir\cmake.pl.backup" "$BuildDir\cmake.pl" -Force
        Write-Host "  Restored cmake.pl" -ForegroundColor Green
    }

    if (Test-Path "$BuildDir\tools.pl.backup") {
        Copy-Item "$BuildDir\tools.pl.backup" "$BuildDir\tools.pl" -Force
        Write-Host "  Restored tools.pl" -ForegroundColor Green
    }

    Write-Host "Restore complete." -ForegroundColor Green
    exit 0
}

# Check if SWI-Prolog exists
if (-not (Test-Path $BuildDir)) {
    Write-Error "SWI-Prolog build directory not found: $BuildDir"
    exit 1
}

# Check if patch files exist
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CmakePatch = Join-Path $ScriptDir "cmake.pl.patched"
$ToolsPatch = Join-Path $ScriptDir "tools.pl.patched"

if (-not (Test-Path $CmakePatch)) {
    Write-Error "cmake.pl.patched not found in $ScriptDir"
    exit 1
}

if (-not (Test-Path $ToolsPatch)) {
    Write-Error "tools.pl.patched not found in $ScriptDir"
    exit 1
}

Write-Host "Applying vcpkg patches to SWI-Prolog..." -ForegroundColor Cyan
Write-Host "  Target: $BuildDir" -ForegroundColor Gray

# Backup originals
if (-not (Test-Path "$BuildDir\cmake.pl.backup")) {
    Copy-Item "$BuildDir\cmake.pl" "$BuildDir\cmake.pl.backup"
    Write-Host "  Backed up cmake.pl" -ForegroundColor Gray
}

if (-not (Test-Path "$BuildDir\tools.pl.backup")) {
    Copy-Item "$BuildDir\tools.pl" "$BuildDir\tools.pl.backup"
    Write-Host "  Backed up tools.pl" -ForegroundColor Gray
}

# Apply patches
Copy-Item $CmakePatch "$BuildDir\cmake.pl" -Force
Write-Host "  Applied cmake.pl patch" -ForegroundColor Green

Copy-Item $ToolsPatch "$BuildDir\tools.pl" -Force
Write-Host "  Applied tools.pl patch" -ForegroundColor Green

# Verify VCPKG_ROOT
$VcpkgRoot = [Environment]::GetEnvironmentVariable("VCPKG_ROOT", "User")
if (-not $VcpkgRoot) {
    $VcpkgRoot = [Environment]::GetEnvironmentVariable("VCPKG_ROOT", "Machine")
}

if ($VcpkgRoot) {
    Write-Host "`nVCPKG_ROOT is set: $VcpkgRoot" -ForegroundColor Green
    $Toolchain = Join-Path $VcpkgRoot "scripts\buildsystems\vcpkg.cmake"
    if (Test-Path $Toolchain) {
        Write-Host "  vcpkg toolchain found" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: vcpkg toolchain not found at $Toolchain" -ForegroundColor Yellow
    }
} else {
    Write-Host "`nWARNING: VCPKG_ROOT not set. Set it with:" -ForegroundColor Yellow
    Write-Host '  [Environment]::SetEnvironmentVariable("VCPKG_ROOT", "C:\vcpkg", "User")' -ForegroundColor Gray
}

Write-Host "`nPatches applied successfully!" -ForegroundColor Green
Write-Host "Restart SWI-Prolog to use the patched build system." -ForegroundColor Cyan
Write-Host "`nTo test: pack_install(rocksdb, [rebuild(true)])." -ForegroundColor Cyan
Write-Host "To restore: .\apply-patches.ps1 -Restore" -ForegroundColor Gray
