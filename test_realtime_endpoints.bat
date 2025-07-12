@echo off
REM Test script for real-time cryptocurrency data endpoints
REM Make sure your Spring Boot application is running on localhost:8081

echo.
echo ==============================================
echo  CRYPTO REAL-TIME DATA TEST SCRIPT
echo ==============================================
echo.

set BASE_URL=http://localhost:8081/api/v1/crypto

echo 1. Testing System Status...
curl -s "%BASE_URL%/system-status" | jq .

echo.
echo 2. Testing Data Freshness Status for BTC...
curl -s "%BASE_URL%/status/BTC" | jq .

echo.
echo 3. Clearing cache for BTC...
curl -X POST -s "%BASE_URL%/clear-cache/BTC" | jq .

echo.
echo 4. Getting fresh BTC data...
curl -s "%BASE_URL%/fresh/BTC/7" | jq .

echo.
echo 5. Getting fresh BTC chart data...
curl -s "%BASE_URL%/fresh-chart/BTC/7" | jq .

echo.
echo 6. Triggering manual refresh for popular cryptocurrencies...
curl -X POST -s "%BASE_URL%/manual-refresh" | jq .

echo.
echo 7. Testing regular analysis with refresh flag...
curl -s "%BASE_URL%/analysis/BTC/7?refresh=true&types=general,technical" | jq .

echo.
echo ==============================================
echo  TEST COMPLETED
echo ==============================================

pause
