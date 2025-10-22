@echo off
REM FFmpeg Export Tool - Test & Format Script
REM Usage: run_tests.bat [test|format|analyze|all]

setlocal enabledelayedexpansion

if "%1"=="" (
    echo Usage: run_tests.bat [command]
    echo.
    echo Commands:
    echo   test          - Run unit tests
    echo   test-models   - Run model tests only
    echo   test-utils    - Run utility tests only
    echo   coverage      - Run tests with coverage report
    echo   format        - Format code with dart format
    echo   format-check  - Check if code is formatted
    echo   analyze       - Run flutter analyze
    echo   lint          - Run strict dart lint
    echo   all           - Run all checks (format-check, analyze, lint, test)
    echo   clean         - Clean build artifacts
    echo.
    goto :eof
)

if "%1"=="test" (
    echo Running unit tests...
    flutter test
    goto :eof
)

if "%1"=="test-models" (
    echo Running model tests...
    flutter test test/models/
    goto :eof
)

if "%1"=="test-utils" (
    echo Running utility tests...
    flutter test test/utils/
    goto :eof
)

if "%1"=="coverage" (
    echo Running tests with coverage...
    flutter test --coverage
    echo.
    echo Coverage report generated in coverage/lcov.info
    goto :eof
)

if "%1"=="format" (
    echo Formatting code...
    dart format .
    echo Done!
    goto :eof
)

if "%1"=="format-check" (
    echo Checking code format...
    dart format --set-exit-if-changed .
    if !errorlevel! equ 0 (
        echo Code is properly formatted
    ) else (
        echo Code formatting issues found! Run 'run_tests.bat format' to fix
    )
    goto :eof
)

if "%1"=="analyze" (
    echo Running flutter analyze...
    flutter analyze
    goto :eof
)

if "%1"=="lint" (
    echo Running dart lint...
    dart analyze --fatal-infos
    goto :eof
)

if "%1"=="all" (
    echo Running all checks...
    echo.
    echo 1. Checking format...
    dart format --set-exit-if-changed .
    if !errorlevel! neq 0 (
        echo   Code formatting issues found!
        exit /b 1
    )
    echo   ✓ Format check passed
    echo.
    
    echo 2. Running analyze...
    flutter analyze
    if !errorlevel! neq 0 (
        echo   Analyze failed!
        exit /b 1
    )
    echo   ✓ Analyze passed
    echo.
    
    echo 3. Running lint...
    dart analyze --fatal-infos
    if !errorlevel! neq 0 (
        echo   Lint check failed!
        exit /b 1
    )
    echo   ✓ Lint passed
    echo.
    
    echo 4. Running tests...
    flutter test
    if !errorlevel! neq 0 (
        echo   Tests failed!
        exit /b 1
    )
    echo   ✓ All tests passed
    echo.
    echo ✓ All checks passed!
    goto :eof
)

if "%1"=="clean" (
    echo Cleaning build artifacts...
    flutter clean
    del /s /q coverage 2>nul
    echo Done!
    goto :eof
)

echo Unknown command: %1
echo Run 'run_tests.bat' with no arguments for usage information.
exit /b 1
