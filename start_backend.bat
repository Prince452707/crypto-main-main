@echo off
REM Spring Boot Backend Launcher
echo.
echo ======================================
echo   Crypto Insight Spring Boot Backend
echo ======================================
echo.

cd /d "d:\programs\spring -boot\crypto-main-main"

echo Starting Spring Boot application...
echo Backend will be available at: http://localhost:8082
echo.
echo Press Ctrl+C to stop the backend
echo.

REM Try different ways to start the application
if exist "mvnw.cmd" (
    echo Using Maven wrapper...
    call mvnw.cmd spring-boot:run
) else (
    echo Maven wrapper not found, trying system Maven...
    mvn spring-boot:run
)

pause
