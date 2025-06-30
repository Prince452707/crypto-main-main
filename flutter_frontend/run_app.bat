@echo off
REM Crypto Insight Flutter App Launcher
echo.
echo ======================================
echo   Crypto Insight Flutter Frontend
echo ======================================
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo Flutter is installed. Version:
flutter --version

echo.
echo Installing dependencies...
flutter pub get

echo.
echo Running Flutter app...
echo.
echo Make sure your Spring Boot backend is running on localhost:8082
echo.
echo Press Ctrl+C to stop the app
echo.

flutter run
