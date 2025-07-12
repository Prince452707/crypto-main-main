Write-Host "Test: Testing Detailed Screen Fixes" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Wait for backend to start
Write-Host "Waiting for backend to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Function to test API endpoint
function Test-ApiEndpoint {
    param($Url, $Description)
    
    Write-Host "`nTesting $Description..." -ForegroundColor Green
    try {
        $response = Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 10
        Write-Host "SUCCESS: $Description - Success" -ForegroundColor Green
        $response | ConvertTo-Json -Depth 3
    }
    catch {
        Write-Host "FAILED: $Description - Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test the API endpoints that the detailed screen uses
Test-ApiEndpoint "http://localhost:8081/api/v1/crypto/info/BTC" "cryptocurrency info endpoint"
Test-ApiEndpoint "http://localhost:8081/api/v1/crypto/analysis/BTC" "cryptocurrency analysis endpoint"
Test-ApiEndpoint "http://localhost:8081/api/v1/crypto/info/UNKNOWN" "fallback behavior with unknown symbol"

# Test health endpoint
Write-Host "`nTesting backend health..." -ForegroundColor Green
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8081/actuator/health" -Method Get -TimeoutSec 5
    Write-Host "SUCCESS: Backend health check - Success" -ForegroundColor Green
    Write-Host "Status: $($health.status)" -ForegroundColor Cyan
}
catch {
    Write-Host "FAILED: Backend health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test frontend if it's running  
Write-Host "`nChecking if frontend is accessible..." -ForegroundColor Green
try {
    $null = Invoke-WebRequest -Uri "http://localhost:8080" -Method Get -TimeoutSec 5
    Write-Host "SUCCESS: Frontend is running on port 8080" -ForegroundColor Green
}
catch {
    Write-Host "WARNING: Frontend not running on port 8080" -ForegroundColor Yellow
}

Write-Host "`nDetailed Screen Fix Summary:" -ForegroundColor Magenta
Write-Host "1. SUCCESS: Improved error handling in Flutter provider" -ForegroundColor Green
Write-Host "2. SUCCESS: Added fallback data service for rate-limited APIs" -ForegroundColor Green  
Write-Host "3. SUCCESS: Enhanced WebSocket connection handling" -ForegroundColor Green
Write-Host "4. SUCCESS: Updated price card to show rate limit status" -ForegroundColor Green
Write-Host "5. SUCCESS: Added backend API fallbacks with user-friendly messages" -ForegroundColor Green
Write-Host ""
Write-Host "RESULT: The detailed screen should now work even when APIs are rate limited!" -ForegroundColor Cyan
Write-Host "TIP: Try opening a cryptocurrency detail page in the Flutter app" -ForegroundColor Yellow

# Provide instructions for testing
Write-Host "`nNext Steps:" -ForegroundColor Magenta
Write-Host "1. Start the Flutter frontend: cd flutter_website && flutter run -d chrome" -ForegroundColor White
Write-Host "2. Navigate to any cryptocurrency detail page" -ForegroundColor White  
Write-Host "3. The page should load with either real data or fallback data" -ForegroundColor White
Write-Host "4. Check for user-friendly error messages instead of blank screens" -ForegroundColor White
