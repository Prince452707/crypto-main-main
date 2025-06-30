#!/usr/bin/env pwsh

Write-Host ""
Write-Host "======================================"
Write-Host "  Crypto Insight Flutter Frontend"
Write-Host "======================================"
Write-Host ""

# Change to the correct directory
Set-Location -Path $PSScriptRoot

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter not found"
    }
    Write-Host "Flutter is installed. Version:"
    Write-Host $flutterVersion
} catch {
    Write-Host "ERROR: Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter: https://flutter.dev/docs/get-started/install" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Installing dependencies..." -ForegroundColor Green
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to install dependencies" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Running Flutter app..." -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: Make sure your Spring Boot backend is running on localhost:8082" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Ctrl+C to stop the app" -ForegroundColor Cyan
Write-Host ""

# Try to run on Chrome first, then Windows desktop
flutter run -d chrome
