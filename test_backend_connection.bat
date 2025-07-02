@echo off
echo ================================
echo Crypto Insight - Backend Test Script
echo ================================
echo.

echo 1. Checking if backend is running on port 8081...
curl -s -o nul -w "HTTP Status: %%{http_code}\n" http://localhost:8081/actuator/health
if %errorlevel% neq 0 (
    echo ❌ Backend not responding on port 8081
    echo.
    echo Please ensure:
    echo 1. Backend is running: mvn spring-boot:run
    echo 2. Port 8081 is available
    echo 3. No firewall blocking the connection
    goto :end
)

echo.
echo 2. Testing market data endpoint...
curl -s -w "HTTP Status: %%{http_code}\n" "http://localhost:8081/api/v1/crypto/market-data?page=1&perPage=5" > test_market_data.json
if %errorlevel% neq 0 (
    echo ❌ Market data endpoint failed
) else (
    echo ✅ Market data endpoint working
)

echo.
echo 3. Testing search endpoint...
curl -s -w "HTTP Status: %%{http_code}\n" "http://localhost:8081/api/v1/crypto/search/BTC?limit=1" > test_search.json
if %errorlevel% neq 0 (
    echo ❌ Search endpoint failed
) else (
    echo ✅ Search endpoint working
)

echo.
echo 4. Testing single crypto endpoint...
curl -s -w "HTTP Status: %%{http_code}\n" "http://localhost:8081/api/v1/crypto/BTC" > test_single_crypto.json
if %errorlevel% neq 0 (
    echo ❌ Single crypto endpoint failed
) else (
    echo ✅ Single crypto endpoint working
)

echo.
echo 5. Testing analysis endpoint...
curl -s -w "HTTP Status: %%{http_code}\n" "http://localhost:8081/api/v1/crypto/analysis/BTC/30" > test_analysis.json
if %errorlevel% neq 0 (
    echo ❌ Analysis endpoint failed
) else (
    echo ✅ Analysis endpoint working
)

echo.
echo ================================
echo Test Results Summary
echo ================================
echo Check the generated JSON files for response data:
echo - test_market_data.json
echo - test_search.json  
echo - test_single_crypto.json
echo - test_analysis.json
echo.

:end
pause
