@echo off
title Crypto Insight - Complete Application Startup
color 0A

echo ===============================================
echo     CRYPTO INSIGHT - COMPLETE STARTUP
echo ===============================================
echo.

echo [1/4] Starting Spring Boot Backend...
echo ===============================================
cd /d "%~dp0"

echo Checking if port 8081 is available...
netstat -an | find "8081" > nul
if %errorlevel% equ 0 (
    echo ⚠️  Port 8081 is already in use. 
    echo Please stop any existing backend service or change the port.
    pause
    exit /b 1
)

echo Starting backend in a new window...
start "Crypto Backend" cmd /k "mvn spring-boot:run"

echo Waiting for backend to start (30 seconds)...
timeout /t 30 /nobreak

echo.
echo [2/4] Testing Backend Connection...
echo ===============================================
curl -s -o nul -w "Backend Health Check: HTTP %%{http_code}\n" http://localhost:8081/actuator/health
if %errorlevel% neq 0 (
    echo ❌ Backend not responding. Please check the backend window for errors.
    pause
    exit /b 1
)

echo ✅ Backend is running successfully!

echo.
echo [3/4] Testing API Endpoints...
echo ===============================================
echo Testing market data...
curl -s -o nul -w "Market Data: HTTP %%{http_code}\n" "http://localhost:8081/api/v1/crypto/market-data?page=1&perPage=1"

echo Testing search...
curl -s -o nul -w "Search: HTTP %%{http_code}\n" "http://localhost:8081/api/v1/crypto/search/BTC?limit=1"

echo Testing crypto details...
curl -s -o nul -w "Crypto Details: HTTP %%{http_code}\n" "http://localhost:8081/api/v1/crypto/BTC"

echo.
echo [4/4] Starting Flutter Frontend...
echo ===============================================
cd /d "%~dp0\flutter_frontend"

echo Checking Flutter installation...
flutter --version > nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed or not in PATH.
    echo Please install Flutter from https://flutter.dev
    pause
    exit /b 1
)

echo Getting Flutter dependencies...
flutter pub get

echo Starting Flutter app in web mode...
start "Crypto Frontend" cmd /k "flutter run -d chrome --web-renderer html"

echo.
echo ===============================================
echo         APPLICATION STARTED SUCCESSFULLY
echo ===============================================
echo.
echo 🌐 Backend API: http://localhost:8081
echo 📱 Frontend App: Will open in Chrome automatically
echo 🔍 Debug Screen: Navigate to /debug in the app
echo.
echo IMPORTANT:
echo - Keep both terminal windows open
echo - Backend logs are in the "Crypto Backend" window
echo - Frontend logs are in the "Crypto Frontend" window
echo.
echo To stop the application:
echo 1. Close the Chrome browser tab
echo 2. Press Ctrl+C in both terminal windows
echo.

echo Ready! 🚀
pause
