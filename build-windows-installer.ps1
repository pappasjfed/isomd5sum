# Windows Installer Build and Test Script
# This script helps build and validate the Windows installer locally

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "isomd5sum Windows Installer Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for required tools
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check CMake
$cmake = Get-Command cmake -ErrorAction SilentlyContinue
if (-not $cmake) {
    Write-Host "❌ CMake not found. Please install CMake 3.12 or later." -ForegroundColor Red
    Write-Host "   Download from: https://cmake.org/download/" -ForegroundColor Red
    exit 1
}
Write-Host "✓ CMake found: $($cmake.Version)" -ForegroundColor Green

# Check NSIS
$nsis = Get-Command makensis -ErrorAction SilentlyContinue
if (-not $nsis) {
    Write-Host "❌ NSIS not found. Please install NSIS." -ForegroundColor Red
    Write-Host "   Option 1: choco install nsis" -ForegroundColor Yellow
    Write-Host "   Option 2: Download from https://nsis.sourceforge.io/Download" -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ NSIS found: $($nsis.Source)" -ForegroundColor Green

# Check Visual Studio
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    $vsPath = & $vsWhere -latest -property installationPath
    Write-Host "✓ Visual Studio found: $vsPath" -ForegroundColor Green
} else {
    Write-Host "⚠ Visual Studio not found. MinGW build will be attempted." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Building Windows installer..." -ForegroundColor Yellow
Write-Host ""

# Create build directory
$buildDir = "build-installer"
if (Test-Path $buildDir) {
    Write-Host "Removing existing build directory..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $buildDir
}

New-Item -ItemType Directory -Path $buildDir | Out-Null
Set-Location $buildDir

# Configure with CMake
Write-Host "Configuring with CMake..." -ForegroundColor Yellow
try {
    cmake -G "Visual Studio 17 2022" -A x64 ..
    if ($LASTEXITCODE -ne 0) {
        throw "CMake configuration failed"
    }
} catch {
    Write-Host "Visual Studio 17 not found, trying Visual Studio 16..." -ForegroundColor Yellow
    try {
        cmake -G "Visual Studio 16 2019" -A x64 ..
        if ($LASTEXITCODE -ne 0) {
            throw "CMake configuration failed"
        }
    } catch {
        Write-Host "Visual Studio build failed, trying MinGW..." -ForegroundColor Yellow
        cmake -G "MinGW Makefiles" ..
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ CMake configuration failed" -ForegroundColor Red
            Set-Location ..
            exit 1
        }
    }
}

Write-Host "✓ CMake configuration successful" -ForegroundColor Green
Write-Host ""

# Build the project
Write-Host "Building project..." -ForegroundColor Yellow
cmake --build . --config Release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Write-Host "✓ Build successful" -ForegroundColor Green
Write-Host ""

# Create the installer
Write-Host "Creating installer with CPack..." -ForegroundColor Yellow
cpack -C Release -G NSIS
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Installer creation failed" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Write-Host "✓ Installer created successfully" -ForegroundColor Green
Write-Host ""

# Find and display the installer
$installer = Get-ChildItem -Filter "isomd5sum-*-win64.exe" | Select-Object -First 1
if ($installer) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Installer created: $($installer.Name)" -ForegroundColor Green
    Write-Host "Location: $($installer.FullName)" -ForegroundColor Green
    Write-Host "Size: $([math]::Round($installer.Length / 1MB, 2)) MB" -ForegroundColor Green
    Write-Host ""
    Write-Host "To test the installer:" -ForegroundColor Yellow
    Write-Host "  1. Run the installer: .\$($installer.Name)" -ForegroundColor White
    Write-Host "  2. Follow the installation wizard" -ForegroundColor White
    Write-Host "  3. Open a new command prompt" -ForegroundColor White
    Write-Host "  4. Test commands: checkisomd5 --help" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "⚠ Installer file not found, but build completed" -ForegroundColor Yellow
    Write-Host "Check the build directory for output files" -ForegroundColor Yellow
}

Set-Location ..
