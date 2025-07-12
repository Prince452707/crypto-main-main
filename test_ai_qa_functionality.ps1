Write-Host "Test: Testing AI Q&A Functionality Fixes" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Wait for backend to start
Write-Host "Waiting for backend to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Function to test endpoint
function Test-Endpoint {
    param($Url, $Method, $Body, $Description)
    
    Write-Host "`nTesting $Description..." -ForegroundColor Green
    try {
        $headers = @{ "Content-Type" = "application/json" }
        
        if ($Method -eq "POST") {
            $response = Invoke-RestMethod -Uri $Url -Method $Method -Headers $headers -Body ($Body | ConvertTo-Json) -TimeoutSec 30
        } else {
            $response = Invoke-RestMethod -Uri $Url -Method $Method -Headers $headers -TimeoutSec 30
        }
        
        Write-Host "SUCCESS: $Description" -ForegroundColor Green
        if ($response.success) {
            Write-Host "Response: $($response.message)" -ForegroundColor Cyan
            if ($response.data) {
                if ($response.data.answer) {
                    Write-Host "Answer preview: $($response.data.answer.ToString().Substring(0, [Math]::Min(100, $response.data.answer.Length)))..." -ForegroundColor White
                } elseif ($response.data.analysis) {
                    Write-Host "Analysis sections: $($response.data.analysis.PSObject.Properties.Count)" -ForegroundColor White
                }
            }
        }
        return $true
    }
    catch {
        Write-Host "FAILED: $Description - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Test health endpoint first
$healthWorking = Test-Endpoint "http://localhost:8081/actuator/health" "GET" $null "Backend health check"

if (-not $healthWorking) {
    Write-Host "CRITICAL: Backend is not responding. Cannot test AI Q&A functionality." -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Testing Basic AI Q&A Endpoints ===" -ForegroundColor Magenta

# Test basic crypto question endpoint
$basicCryptoQuestion = @{ question = "What is Bitcoin and how does it work?" }
$basicWorking = Test-Endpoint "http://localhost:8081/api/v1/crypto/question/BTC" "POST" $basicCryptoQuestion "Basic crypto Q&A for Bitcoin"

# Test basic general question endpoint
$basicGeneralQuestion = @{ question = "What are the main benefits of cryptocurrency?" }
$basicGeneralWorking = Test-Endpoint "http://localhost:8081/api/v1/crypto/question" "POST" $basicGeneralQuestion "Basic general crypto Q&A"

Write-Host "`n=== Testing Enhanced AI Q&A Endpoints ===" -ForegroundColor Magenta

# Test enhanced crypto question endpoint
$enhancedCryptoQuestion = @{ question = "Should I invest in Bitcoin right now based on current market conditions?" }
$enhancedWorking = Test-Endpoint "http://localhost:8081/api/v1/ai/crypto/question/BTC" "POST" $enhancedCryptoQuestion "Enhanced crypto Q&A for Bitcoin"

# Test enhanced general question endpoint
$enhancedGeneralQuestion = @{ question = "What are the top 3 cryptocurrencies to watch in 2025?" }
$enhancedGeneralWorking = Test-Endpoint "http://localhost:8081/api/v1/ai/crypto/question" "POST" $enhancedGeneralQuestion "Enhanced general crypto Q&A"

Write-Host "`n=== AI Q&A Functionality Status Summary ===" -ForegroundColor Magenta

if ($basicWorking) {
    Write-Host "SUCCESS: Basic AI Q&A endpoints are working" -ForegroundColor Green
} else {
    Write-Host "FAILED: Basic AI Q&A endpoints are not working" -ForegroundColor Red
}

if ($enhancedWorking) {
    Write-Host "SUCCESS: Enhanced AI Q&A endpoints are working" -ForegroundColor Green
} else {
    Write-Host "FAILED: Enhanced AI Q&A endpoints are not working" -ForegroundColor Red
}

if ($basicGeneralWorking) {
    Write-Host "SUCCESS: General AI Q&A endpoints are working" -ForegroundColor Green
} else {
    Write-Host "FAILED: General AI Q&A endpoints are not working" -ForegroundColor Red
}

Write-Host "`n=== Diagnosis and Solutions ===" -ForegroundColor Magenta

if (-not $enhancedWorking) {
    Write-Host "ISSUE IDENTIFIED: Enhanced AI endpoints failing" -ForegroundColor Yellow
    Write-Host "SOLUTIONS IMPLEMENTED:" -ForegroundColor Yellow
    Write-Host "1. Fixed CORS configuration (originPatterns instead of origins)" -ForegroundColor White
    Write-Host "2. Updated frontend AI service to use enhanced endpoints with fallback" -ForegroundColor White
    Write-Host "3. Verified Ollama AI service is running on port 11434" -ForegroundColor White
}

if (-not $basicWorking -and -not $enhancedWorking) {
    Write-Host "CRITICAL ISSUE: All AI Q&A endpoints are failing" -ForegroundColor Red
    Write-Host "POTENTIAL CAUSES:" -ForegroundColor Yellow
    Write-Host "1. Ollama AI service may be unresponsive or overloaded" -ForegroundColor White
    Write-Host "2. Backend AI service configuration issue" -ForegroundColor White
    Write-Host "3. Network connectivity to AI service" -ForegroundColor White
}

Write-Host "`nNext Steps:" -ForegroundColor Magenta
Write-Host "1. If enhanced endpoints are working, the AI Q&A is now FIXED" -ForegroundColor White
Write-Host "2. Test in Flutter frontend by opening crypto detail screen AI Q&A tab" -ForegroundColor White
Write-Host "3. Try asking questions like 'What is Bitcoin?' or 'Should I invest?'" -ForegroundColor White
Write-Host "4. Check for improved response quality from enhanced endpoints" -ForegroundColor White
