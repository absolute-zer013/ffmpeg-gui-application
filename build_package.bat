@echo off
REM FFmpeg Export Tool - Build and Package Script
REM This script creates release packages for distribution

setlocal enabledelayedexpansion

set BUILD_DATE=%date:~-4%%date:~-10,2%%date:~-7,2%
set BUILD_TIME=%time:~0,2%%time:~3,2%%time:~6,2%

echo.
echo =====================================
echo FFmpeg Export Tool - Build Package
echo =====================================
echo Build Date: %date% %time%
echo.

if "%1"=="" (
    echo Usage: build_package.bat [build^|package^|all]
    echo.
    echo Commands:
    echo   build    - Build Windows release executable
    echo   package  - Create distribution package (requires build first)
    echo   all      - Build and create distribution package
    echo.
    goto :eof
)

if "%1"=="build" goto :build
if "%1"=="package" goto :package
if "%1"=="all" goto :build

:build
echo [1/3] Running all checks before build...
call .\run_tests.bat format-check
if !errorlevel! neq 0 (
    echo ERROR: Code formatting failed
    exit /b 1
)
echo.

echo [2/3] Running tests...
call .\run_tests.bat test
if !errorlevel! neq 0 (
    echo ERROR: Tests failed
    exit /b 1
)
echo.

echo [3/3] Building Windows release...
flutter build windows --release
if !errorlevel! neq 0 (
    echo ERROR: Build failed
    exit /b 1
)
echo.
echo Build completed successfully!
echo Executable: build\windows\x64\runner\Release\export_file.exe

if "%1"=="all" goto :package
goto :eof

:package
if not exist "build\windows\x64\runner\Release\export_file.exe" (
    echo ERROR: Executable not found. Run 'build_package.bat build' first.
    exit /b 1
)

echo.
echo Creating distribution package...

set OUTPUT_DIR=dist
set BUILD_VERSION=1.0.0
set PACKAGE_NAME=FFmpegExportTool-v%BUILD_VERSION%-release

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo Copying files...
REM Create package structure
mkdir "%OUTPUT_DIR%\%PACKAGE_NAME%"
mkdir "%OUTPUT_DIR%\%PACKAGE_NAME%\bin"
mkdir "%OUTPUT_DIR%\%PACKAGE_NAME%\data"
mkdir "%OUTPUT_DIR%\%PACKAGE_NAME%\docs"

REM Copy executable
copy "build\windows\x64\runner\Release\export_file.exe" "%OUTPUT_DIR%\%PACKAGE_NAME%\bin\" >nul

REM Copy required DLLs
copy "build\windows\x64\runner\Release\flutter_windows.dll" "%OUTPUT_DIR%\%PACKAGE_NAME%\bin\" >nul
copy "build\windows\x64\runner\Release\desktop_drop_plugin.dll" "%OUTPUT_DIR%\%PACKAGE_NAME%\bin\" >nul
copy "build\windows\x64\runner\Release\local_notifier_plugin.dll" "%OUTPUT_DIR%\%PACKAGE_NAME%\bin\" >nul

REM Copy data files
xcopy "build\windows\x64\runner\Release\data" "%OUTPUT_DIR%\%PACKAGE_NAME%\data" /E /I /Y >nul

REM Copy documentation
copy "README.md" "%OUTPUT_DIR%\%PACKAGE_NAME%\docs\" >nul
copy "FEATURES.md" "%OUTPUT_DIR%\%PACKAGE_NAME%\docs\" >nul
copy "TESTING.md" "%OUTPUT_DIR%\%PACKAGE_NAME%\docs\" >nul

REM Create README for distribution
(
    echo # FFmpeg Export Tool - Release %BUILD_VERSION%
    echo.
    echo ## Installation
    echo.
    echo 1. Ensure FFmpeg is installed on your system
    echo 2. Add FFmpeg to your system PATH
    echo 3. Run export_file.exe from the bin\ folder
    echo.
    echo ## Requirements
    echo.
    echo - Windows 10 or later
    echo - FFmpeg installed and in PATH
    echo - Visual C++ Runtime ^(included^)
    echo.
    echo ## Features
    echo.
    echo - Fast MKV/MP4/AVI/MOV export with stream selection
    echo - Batch audio and subtitle filtering
    echo - Real-time progress tracking
    echo - Parallel export support
    echo - Export profiles for common configurations
    echo.
    echo See docs/FEATURES.md for complete feature list.
) > "%OUTPUT_DIR%\%PACKAGE_NAME%\README.txt"

REM Create portable zip
echo Creating portable package...
cd "%OUTPUT_DIR%"
if exist "%PACKAGE_NAME%.zip" del "%PACKAGE_NAME%.zip"
powershell -command "Add-Type -Assembly 'System.IO.Compression.FileSystem'; [System.IO.Compression.ZipFile]::CreateFromDirectory('%PACKAGE_NAME%', '%PACKAGE_NAME%.zip')"
cd ..

echo.
echo ✓ Package created: %OUTPUT_DIR%\%PACKAGE_NAME%.zip
echo.
echo Contents:
echo   bin\export_file.exe          - Application executable
echo   bin\*.dll                     - Required libraries
echo   data\                         - Application data files
echo   docs\                         - Documentation
echo   README.txt                    - Quick start guide
echo.
echo Distribution package ready for release!
goto :eof
