# FFmpeg Export Tool - Test and Format Script
# Usage: .\run_tests.ps1 [command]

param(
    [Parameter(Position = 0)]
    [ValidateSet("test", "test-models", "test-utils", "coverage", "format", "format-check", "analyze", "lint", "all", "clean")]
    [string]$Command = ""
)

function Show-Usage {
    Write-Host "Usage: .\run_tests.ps1 [command]" -ForegroundColor Green
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Cyan
    Write-Host "  test          - Run unit tests"
    Write-Host "  test-models   - Run model tests only"
    Write-Host "  test-utils    - Run utility tests only"
    Write-Host "  coverage      - Run tests with coverage report"
    Write-Host "  format        - Format code with dart format"
    Write-Host "  format-check  - Check if code is formatted"
    Write-Host "  analyze       - Run flutter analyze"
    Write-Host "  lint          - Run strict dart lint"
    Write-Host "  all           - Run all checks"
    Write-Host "  clean         - Clean build artifacts"
}

if ([string]::IsNullOrEmpty($Command)) {
    Show-Usage
    exit 0
}

switch ($Command) {
    "test" {
        Write-Host "Running unit tests..." -ForegroundColor Yellow
        flutter test
        exit $LASTEXITCODE
    }
    
    "test-models" {
        Write-Host "Running model tests..." -ForegroundColor Yellow
        flutter test test/models/
        exit $LASTEXITCODE
    }
    
    "test-utils" {
        Write-Host "Running utility tests..." -ForegroundColor Yellow
        flutter test test/utils/
        exit $LASTEXITCODE
    }
    
    "coverage" {
        Write-Host "Running tests with coverage..." -ForegroundColor Yellow
        flutter test --coverage
        Write-Host ""
        Write-Host "Coverage report generated in coverage/lcov.info" -ForegroundColor Green
        exit $LASTEXITCODE
    }
    
    "format" {
        Write-Host "Formatting code..." -ForegroundColor Yellow
        dart format .
        Write-Host "Done!" -ForegroundColor Green
        exit 0
    }
    
    "format-check" {
        Write-Host "Checking code format..." -ForegroundColor Yellow
        dart format --set-exit-if-changed .
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Code is properly formatted" -ForegroundColor Green
        } else {
            Write-Host "Code formatting issues found! Run format to fix" -ForegroundColor Red
        }
        exit $LASTEXITCODE
    }
    
    "analyze" {
        Write-Host "Running flutter analyze..." -ForegroundColor Yellow
        flutter analyze
        exit $LASTEXITCODE
    }
    
    "lint" {
        Write-Host "Running dart lint..." -ForegroundColor Yellow
        dart analyze --fatal-infos
        exit $LASTEXITCODE
    }
    
    "all" {
        Write-Host "Running all checks..." -ForegroundColor Cyan
        
        Write-Host ""
        Write-Host "1. Checking format..." -ForegroundColor Yellow
        dart format --set-exit-if-changed .
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Code formatting issues found!" -ForegroundColor Red
            exit 1
        }
        Write-Host "   OK: Format check passed" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "2. Running analyze..." -ForegroundColor Yellow
        flutter analyze
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Analyze failed!" -ForegroundColor Red
            exit 1
        }
        Write-Host "   OK: Analyze passed" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "3. Running lint..." -ForegroundColor Yellow
        dart analyze --fatal-infos
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Lint check failed!" -ForegroundColor Red
            exit 1
        }
        Write-Host "   OK: Lint passed" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "4. Running tests..." -ForegroundColor Yellow
        flutter test
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Tests failed!" -ForegroundColor Red
            exit 1
        }
        Write-Host "   OK: All tests passed" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "OK: All checks passed!" -ForegroundColor Green
        exit 0
    }
    
    "clean" {
        Write-Host "Cleaning build artifacts..." -ForegroundColor Yellow
        flutter clean
        if (Test-Path "coverage") {
            Remove-Item -Recurse -Force "coverage" -ErrorAction SilentlyContinue
        }
        Write-Host "Done!" -ForegroundColor Green
        exit 0
    }
    
    default {
        Write-Host "Unknown command: $Command" -ForegroundColor Red
        Show-Usage
        exit 1
    }
}
