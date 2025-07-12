@echo off
REM Test script for the Focused Crypto System (Windows version)
REM This script tests the new API endpoints for comprehensive crypto data

set BASE_URL=http://localhost:8081/api/v1/crypto/focused

echo === Testing Focused Crypto System ===
echo Base URL: %BASE_URL%
echo.

echo Testing: Get AVAX (Avalanche) comprehensive data
echo Endpoint: GET %BASE_URL%/avalanche
curl -s "%BASE_URL%/avalanche" -H "Content-Type: application/json"
echo.
echo ---
echo.

echo Testing: Get Bitcoin comprehensive data
echo Endpoint: GET %BASE_URL%/bitcoin
curl -s "%BASE_URL%/bitcoin" -H "Content-Type: application/json"
echo.
echo ---
echo.

echo Testing: Force refresh AVAX data
echo Endpoint: GET %BASE_URL%/avalanche?forceRefresh=true
curl -s "%BASE_URL%/avalanche?forceRefresh=true" -H "Content-Type: application/json"
echo.
echo ---
echo.

echo Testing: Get rate limiting status
echo Endpoint: GET %BASE_URL%/status/rate-limits
curl -s "%BASE_URL%/status/rate-limits" -H "Content-Type: application/json"
echo.
echo ---
echo.

echo Testing: Refresh Bitcoin data
echo Endpoint: POST %BASE_URL%/bitcoin/refresh
curl -s -X POST "%BASE_URL%/bitcoin/refresh" -H "Content-Type: application/json"
echo.
echo ---
echo.

echo Testing: Clear Bitcoin cache
echo Endpoint: DELETE %BASE_URL%/bitcoin/cache
curl -s -X DELETE "%BASE_URL%/bitcoin/cache" -H "Content-Type: application/json"
echo.
echo ---
echo.

echo Testing: Preload popular cryptocurrencies
echo Endpoint: POST %BASE_URL%/preload
curl -s -X POST "%BASE_URL%/preload" -H "Content-Type: application/json"
echo.
echo ---
echo.

echo Testing various crypto identifiers:
for %%c in (ethereum ETH binancecoin BNB solana SOL cardano ADA) do (
    echo Testing crypto: %%c
    curl -s "%BASE_URL%/%%c" -H "Content-Type: application/json"
    echo.
)

echo.
echo === Test Summary ===
echo 1. Check that the backend is running on port 8081
echo 2. Verify that the new endpoints are responding
echo 3. Monitor the backend logs for rate limiting information
echo 4. Check that data is being aggregated from multiple providers
echo.
echo Expected benefits:
echo - Reduced 429 rate limiting errors
echo - More comprehensive crypto data
echo - Better error handling and fallbacks
echo - Intelligent caching and provider selection
echo.
echo To monitor rate limits in real-time:
echo curl -s "%BASE_URL%/status/rate-limits"

pause
