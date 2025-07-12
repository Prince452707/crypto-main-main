@echo off
cls
echo ===============================================
echo    🚀 CRYPTO INSIGHT PRO - ULTRA-FAST MODE
echo ===============================================
echo.

REM Kill any existing processes
echo 🔄 Cleaning up existing processes...
taskkill /f /im java.exe 2>nul
taskkill /f /im dart.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo 🎯 Starting Backend with Ultra-Fast Optimizations...
echo.

REM Start backend in background
start "Crypto Backend" cmd /k "call start_backend_ultra_fast.bat"

echo ⏳ Waiting for backend to initialize...
timeout /t 10 /nobreak

echo.
echo 🌐 Starting Flutter Frontend...
echo.

REM Navigate to Flutter directory and start
cd /d "flutter_website"

REM Clean and get dependencies
echo 📦 Cleaning Flutter cache...
call flutter clean >nul 2>&1
call flutter pub get >nul 2>&1

echo.
echo 🚀 Launching Flutter Web App...
echo.

REM Start Flutter with performance optimizations
start "Flutter Frontend" cmd /k "flutter run -d web-server --web-port=3000 --release --verbose"

echo.
echo ✅ ULTRA-FAST CRYPTO INSIGHT PRO STARTED!
echo.
echo 🔗 Access URLs:
echo    Frontend: http://localhost:3000
echo    Backend API: http://localhost:8081/api/v1
echo    Ultra-Fast API: http://localhost:8081/api/v1/ultra-fast
echo    Health Check: http://localhost:8081/api/v1/ultra-fast/health
echo.
echo 💡 Tips for Maximum Performance:
echo    - Data is preloaded for instant access
echo    - Aggressive caching reduces load times
echo    - Parallel processing for ultra-fast responses
echo    - Optimized network connections
echo.
echo Press any key to open frontend in browser...
pause >nul

start http://localhost:3000

echo.
echo 🎉 Enjoy ultra-fast crypto insights!
pause
