#!/usr/bin/env powershell
# API Health Check Script
# This script tests all API endpoints to ensure they're working properly

Write-Host "=== API HEALTH CHECK ===" -ForegroundColor Green
Write-Host "Testing all API endpoints..." -ForegroundColor Yellow
Write-Host ""

$baseUrl = "http://localhost:8081/api/v1"
$testResults = @()

# Test function
function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url,
        [string]$ExpectedStatus = "200"
    )
    
    Write-Host "Testing $Name..." -ForegroundColor Cyan
    
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -ErrorAction Stop
        $statusCode = $response.StatusCode
        
        if ($statusCode -eq $ExpectedStatus) {
            Write-Host "✅ $Name: SUCCESS (Status: $statusCode)" -ForegroundColor Green
            $testResults += [PSCustomObject]@{
                Endpoint = $Name
                URL = $Url
                Status = "✅ PASS"
                StatusCode = $statusCode
                Details = "Working properly"
            }
        } else {
            Write-Host "⚠️ $Name: UNEXPECTED STATUS (Status: $statusCode)" -ForegroundColor Yellow
            $testResults += [PSCustomObject]@{
                Endpoint = $Name
                URL = $Url
                Status = "⚠️ WARN"
                StatusCode = $statusCode
                Details = "Unexpected status code"
            }
        }
    } catch {
        Write-Host "❌ $Name: FAILED - $($_.Exception.Message)" -ForegroundColor Red
        $testResults += [PSCustomObject]@{
            Endpoint = $Name
            URL = $Url
            Status = "❌ FAIL"
            StatusCode = "Error"
            Details = $_.Exception.Message
        }
    }
    Write-Host ""
}

# Test all endpoints
Write-Host "Testing Core API Endpoints:" -ForegroundColor Magenta
Write-Host "=================================" -ForegroundColor Magenta

# 1. Market Data
Test-Endpoint -Name "Market Data" -Url "$baseUrl/crypto/market-data?page=1&perPage=5"

# 2. Search
Test-Endpoint -Name "Search Bitcoin" -Url "$baseUrl/crypto/search/bitcoin?limit=3"

# 3. Cryptocurrency by Symbol
Test-Endpoint -Name "Get Bitcoin by Symbol" -Url "$baseUrl/crypto/BTC"

# 4. Cryptocurrency Details
Test-Endpoint -Name "Get Bitcoin Details" -Url "$baseUrl/crypto/details/bitcoin"

# 5. Price Chart
Test-Endpoint -Name "Price Chart" -Url "$baseUrl/crypto/price-chart/BTC?days=7"

# 6. Market Chart
Test-Endpoint -Name "Market Chart" -Url "$baseUrl/crypto/BTC/market-chart?days=7"

# 7. Analysis
Test-Endpoint -Name "Analysis" -Url "$baseUrl/crypto/analysis/BTC?days=7"

# 8. News
Test-Endpoint -Name "General News" -Url "$baseUrl/crypto/news?limit=3"

# 9. News by Symbol
Test-Endpoint -Name "Bitcoin News" -Url "$baseUrl/crypto/BTC/news?limit=3"

# Results Summary
Write-Host "=== SUMMARY ===" -ForegroundColor Green
Write-Host ""

$passCount = ($testResults | Where-Object { $_.Status -eq "✅ PASS" }).Count
$warnCount = ($testResults | Where-Object { $_.Status -eq "⚠️ WARN" }).Count
$failCount = ($testResults | Where-Object { $_.Status -eq "❌ FAIL" }).Count

Write-Host "✅ PASSED: $passCount" -ForegroundColor Green
Write-Host "⚠️ WARNINGS: $warnCount" -ForegroundColor Yellow
Write-Host "❌ FAILED: $failCount" -ForegroundColor Red
Write-Host ""

# Detailed results
Write-Host "=== DETAILED RESULTS ===" -ForegroundColor Cyan
$testResults | Format-Table -AutoSize

# Frontend-Backend Connection Test
Write-Host "=== FRONTEND-BACKEND CONNECTION TEST ===" -ForegroundColor Magenta
Write-Host "Testing if Flutter app can connect to backend..." -ForegroundColor Yellow

$frontendBaseUrl = "http://localhost:8081"
$apiPath = "/api/v1"
$fullBaseUrl = "$frontendBaseUrl$apiPath"

Write-Host "Frontend Configuration:" -ForegroundColor Cyan
Write-Host "  Base URL: $frontendBaseUrl" -ForegroundColor White
Write-Host "  API Path: $apiPath" -ForegroundColor White
Write-Host "  Full URL: $fullBaseUrl" -ForegroundColor White
Write-Host ""

Test-Endpoint -Name "Frontend Market Data Connection" -Url "$fullBaseUrl/crypto/market-data?page=1&perPage=50"
Test-Endpoint -Name "Frontend Search Connection" -Url "$fullBaseUrl/crypto/search/bitcoin?limit=10"

# Health Status
Write-Host "=== OVERALL HEALTH STATUS ===" -ForegroundColor Green
if ($failCount -eq 0) {
    Write-Host "🎉 ALL SYSTEMS OPERATIONAL!" -ForegroundColor Green
    Write-Host "Backend is fully functional and ready for frontend integration." -ForegroundColor Green
} elseif ($failCount -lt 3) {
    Write-Host "⚠️ MOSTLY OPERATIONAL" -ForegroundColor Yellow
    Write-Host "Some endpoints need attention, but core functionality is working." -ForegroundColor Yellow
} else {
    Write-Host "❌ CRITICAL ISSUES DETECTED" -ForegroundColor Red
    Write-Host "Multiple endpoints are failing. Backend needs immediate attention." -ForegroundColor Red
}

Write-Host ""
Write-Host "Health check completed at $(Get-Date)" -ForegroundColor Gray
