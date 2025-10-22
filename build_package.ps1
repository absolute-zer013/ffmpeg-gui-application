# FFmpeg Export Tool - Build and Package Script
# Usage: .\build_package.ps1 [build|package|all]

param(
    [Parameter(Position = 0)]
    [ValidateSet("build", "package", "all")]
    [string]$Command = ""
)

# Configuration
$BuildVersion = "1.0.0"
$OutputDir = "dist"
$PackageName = "FFmpegExportTool-v$BuildVersion-release"
$BuildPath = "build\windows\x64\runner\Release"
$ExePath = "$BuildPath\export_file.exe"

function Show-Usage {
    Write-Host "Usage: .\build_package.ps1 [command]" -ForegroundColor Green
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Cyan
    Write-Host "  build    - Build Windows release executable"
    Write-Host "  package  - Create distribution package (requires build first)"
    Write-Host "  all      - Build and create distribution package"
}

function Invoke-Build {
    Write-Host "Building Windows Release..." -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "1. Running format check..." -ForegroundColor Yellow
    & .\run_tests.ps1 format-check
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Code formatting failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "2. Running tests..." -ForegroundColor Yellow
    & .\run_tests.ps1 test
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Tests failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "3. Building Windows release..." -ForegroundColor Yellow
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Build failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "Build completed successfully!" -ForegroundColor Green
    Write-Host "Executable: $ExePath" -ForegroundColor Green
}

function Invoke-Package {
    if (!(Test-Path $ExePath)) {
        Write-Host "ERROR: Executable not found at $ExePath" -ForegroundColor Red
        Write-Host "Run 'build_package.ps1 build' first" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host ""
    Write-Host "Creating Distribution Package..." -ForegroundColor Cyan
    
    # Create directories
    if (!(Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir | Out-Null
    }
    
    $PackagePath = "$OutputDir\$PackageName"
    if (Test-Path $PackagePath) {
        Remove-Item -Recurse -Force $PackagePath
    }
    
    New-Item -ItemType Directory -Path "$PackagePath\bin" | Out-Null
    New-Item -ItemType Directory -Path "$PackagePath\data" | Out-Null
    New-Item -ItemType Directory -Path "$PackagePath\docs" | Out-Null
    
    Write-Host "Copying files..." -ForegroundColor Yellow
    
    # Copy executable and DLLs
    Copy-Item "$BuildPath\export_file.exe" "$PackagePath\bin\" -Force
    Copy-Item "$BuildPath\flutter_windows.dll" "$PackagePath\bin\" -Force
    Copy-Item "$BuildPath\desktop_drop_plugin.dll" "$PackagePath\bin\" -Force -ErrorAction SilentlyContinue
    Copy-Item "$BuildPath\local_notifier_plugin.dll" "$PackagePath\bin\" -Force -ErrorAction SilentlyContinue
    
    # Copy data files
    Copy-Item "$BuildPath\data" "$PackagePath\data" -Recurse -Force
    
    # Copy documentation
    Copy-Item "README.md" "$PackagePath\docs\" -Force
    Copy-Item "FEATURES.md" "$PackagePath\docs\" -Force
    Copy-Item "TESTING.md" "$PackagePath\docs\" -Force
    
    # Create README for distribution
    $ReadmeContent = @"
# FFmpeg Export Tool - Release $BuildVersion

## Installation

1. Ensure FFmpeg is installed on your system
2. Add FFmpeg to your system PATH
3. Run export_file.exe from the bin\ folder

## Requirements

- Windows 10 or later
- FFmpeg installed and in PATH
- Visual C++ Runtime (included)

## Features

- Fast MKV/MP4/AVI/MOV export with stream selection
- Batch audio and subtitle filtering
- Real-time progress tracking
- Parallel export support
- Export profiles for common configurations

See docs/FEATURES.md for complete feature list.

## Troubleshooting

If you encounter any issues:
1. Verify FFmpeg is installed: `ffmpeg -version`
2. Add FFmpeg to PATH if not already done
3. Check system requirements (Windows 10+)
4. See docs/TESTING.md for advanced options
"@
    
    $ReadmeContent | Out-File -FilePath "$PackagePath\README.txt" -Encoding ASCII
    
    # Create ZIP file
    Write-Host "Creating ZIP archive..." -ForegroundColor Yellow
    $ZipPath = "$OutputDir\$PackageName.zip"
    
    if (Test-Path $ZipPath) {
        Remove-Item $ZipPath -Force
    }
    
    Add-Type -Assembly "System.IO.Compression.FileSystem"
    [System.IO.Compression.ZipFile]::CreateFromDirectory($PackagePath, $ZipPath)
    
    Write-Host ""
    Write-Host "✓ Package created: $ZipPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "Contents:" -ForegroundColor Cyan
    Write-Host "  bin\export_file.exe          - Application executable"
    Write-Host "  bin\*.dll                     - Required libraries"
    Write-Host "  data\                         - Application data files"
    Write-Host "  docs\                         - Documentation"
    Write-Host "  README.txt                    - Quick start guide"
    Write-Host ""
    Write-Host "Distribution package ready for release! 🎉" -ForegroundColor Green
}

if ([string]::IsNullOrEmpty($Command)) {
    Show-Usage
    exit 0
}

switch ($Command) {
    "build" {
        Invoke-Build
        exit $LASTEXITCODE
    }
    
    "package" {
        Invoke-Package
        exit $LASTEXITCODE
    }
    
    "all" {
        Invoke-Build
        if ($LASTEXITCODE -ne 0) {
            exit 1
        }
        Invoke-Package
        exit $LASTEXITCODE
    }
}
