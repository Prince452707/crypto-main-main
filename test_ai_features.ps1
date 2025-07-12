# Enhanced AI Features Test Script for Windows PowerShell
# This script tests the AI Q&A and Similar Coin features

param(
    [string]$BaseUrl = "http://localhost:8080",
    [switch]$Verbose
)

$AIBaseUrl = "$BaseUrl/api/v1/ai"
$ProgressPreference = 'SilentlyContinue'

function Write-TestResult {
    param($TestName, $Success, $Details = "")
    if ($Success) {
        Write-Host "✅ $TestName" -ForegroundColor Green
        if ($Details -and $Verbose) {
            Write-Host "   $Details" -ForegroundColor Gray
        }
    } else {
        Write-Host "❌ $TestName" -ForegroundColor Red
        if ($Details) {
            Write-Host "   $Details" -ForegroundColor Yellow
        }
    }
}

function Test-AIHealth {
    Write-Host "`n🔍 Testing AI Service Health..." -ForegroundColor Cyan
    
    try {
        $response = Invoke-RestMethod -Uri "$AIBaseUrl/health" -Method Get -TimeoutSec 10
        if ($response.success) {
            $features = $response.data.features -join ", "
            Write-TestResult "AI Service Health" $true "Features: $features"
            return $true
        } else {
            Write-TestResult "AI Service Health" $false "API returned success=false"
            return $false
        }
    } catch {
        Write-TestResult "AI Service Health" $false $_.Exception.Message
        return $false
    }
}

function Test-CryptoQA {
    Write-Host "`n🤖 Testing Crypto-Specific Q&A..." -ForegroundColor Cyan
    
    $testCases = @(
        @{ Symbol = "BTC"; Question = "Should I invest in Bitcoin right now?"; ExpectedType = "INVESTMENT" },
        @{ Symbol = "ETH"; Question = "What is the price prediction for Ethereum?"; ExpectedType = "PRICE_PREDICTION" },
        @{ Symbol = "ADA"; Question = "What are the risks of investing in Cardano?"; ExpectedType = "RISK_ASSESSMENT" }
    )
    
    $successCount = 0
    
    foreach ($testCase in $testCases) {
        Write-Host "  Testing $($testCase.Symbol): $($testCase.Question.Substring(0, [Math]::Min(50, $testCase.Question.Length)))..." -ForegroundColor Gray
        
        try {
            $body = @{ question = $testCase.Question } | ConvertTo-Json
            $response = Invoke-RestMethod -Uri "$AIBaseUrl/crypto/question/$($testCase.Symbol)" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
            
            if ($response.success -and $response.data.success) {
                $answerLength = $response.data.answer.Length
                $questionType = $response.data.questionType
                
                if ($answerLength -gt 50) {
                    Write-TestResult "$($testCase.Symbol) Q&A" $true "Type: $questionType, Length: $answerLength chars"
                    $successCount++
                } else {
                    Write-TestResult "$($testCase.Symbol) Q&A" $false "Answer too short: $answerLength chars"
                }
            } else {
                Write-TestResult "$($testCase.Symbol) Q&A" $false "API returned success=false"
            }
        } catch {
            Write-TestResult "$($testCase.Symbol) Q&A" $false $_.Exception.Message
        }
        
        Start-Sleep -Seconds 1
    }
    
    Write-Host "  Crypto Q&A Results: $successCount/$($testCases.Count) successful" -ForegroundColor $(if ($successCount -eq $testCases.Count) { "Green" } else { "Yellow" })
    return $successCount -eq $testCases.Count
}

function Test-GeneralQA {
    Write-Host "`n🎓 Testing General Crypto Q&A..." -ForegroundColor Cyan
    
    $questions = @(
        "What is cryptocurrency?",
        "How does blockchain technology work?",
        "What is DeFi and how does it work?",
        "What are the risks of cryptocurrency investment?"
    )
    
    $successCount = 0
    
    foreach ($question in $questions) {
        Write-Host "  Testing: $($question.Substring(0, [Math]::Min(40, $question.Length)))..." -ForegroundColor Gray
        
        try {
            $body = @{ question = $question } | ConvertTo-Json
            $response = Invoke-RestMethod -Uri "$AIBaseUrl/crypto/question" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
            
            if ($response.success -and $response.data.success) {
                $answerLength = $response.data.answer.Length
                $questionType = $response.data.questionType
                
                if ($answerLength -gt 50) {
                    Write-TestResult "General Q&A" $true "Type: $questionType, Length: $answerLength chars"
                    $successCount++
                } else {
                    Write-TestResult "General Q&A" $false "Answer too short: $answerLength chars"
                }
            } else {
                Write-TestResult "General Q&A" $false "API returned success=false"
            }
        } catch {
            Write-TestResult "General Q&A" $false $_.Exception.Message
        }
        
        Start-Sleep -Seconds 1
    }
    
    Write-Host "  General Q&A Results: $successCount/$($questions.Count) successful" -ForegroundColor $(if ($successCount -eq $questions.Count) { "Green" } else { "Yellow" })
    return $successCount -eq $questions.Count
}

function Test-SimilarCoins {
    Write-Host "`n🔍 Testing Similar Coin Recommendations..." -ForegroundColor Cyan
    
    $symbols = @("BTC", "ETH", "ADA", "SOL", "DOGE")
    $successCount = 0
    
    foreach ($symbol in $symbols) {
        Write-Host "  Testing similar coins for $symbol..." -ForegroundColor Gray
        
        try {
            $uri = "$AIBaseUrl/crypto/similar/$symbol" + "?limit=5&includeAnalysis=true&includeMarketData=false"
            $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 30
            
            if ($response.success -and $response.data.success) {
                $similarCoins = $response.data.similar_cryptocurrencies
                $coinCount = $similarCoins.Count
                
                if ($coinCount -gt 0) {
                    $topCoins = $similarCoins[0..([Math]::Min(2, $coinCount-1))] | ForEach-Object { "$($_.symbol) ($($_.similarity_score))" }
                    Write-TestResult "$symbol Similar Coins" $true "Found $coinCount coins: $($topCoins -join ', ')"
                    $successCount++
                } else {
                    Write-TestResult "$symbol Similar Coins" $false "No similar coins found"
                }
            } else {
                Write-TestResult "$symbol Similar Coins" $false "API returned success=false"
            }
        } catch {
            Write-TestResult "$symbol Similar Coins" $false $_.Exception.Message
        }
        
        Start-Sleep -Seconds 1
    }
    
    Write-Host "  Similar Coins Results: $successCount/$($symbols.Count) successful" -ForegroundColor $(if ($successCount -eq $symbols.Count) { "Green" } else { "Yellow" })
    return $successCount -eq $symbols.Count
}

function Test-Comparison {
    Write-Host "`n⚖️ Testing Cryptocurrency Comparison..." -ForegroundColor Cyan
    
    try {
        $body = @{ symbols = @("BTC", "ETH", "ADA") } | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "$AIBaseUrl/crypto/compare" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        
        if ($response.success) {
            $analysisLength = $response.data.analysis.Length
            $matrixCount = $response.data.similarity_matrix.Count
            Write-TestResult "Crypto Comparison" $true "Analysis: $analysisLength chars, Matrix: $matrixCount pairs"
            return $true
        } else {
            Write-TestResult "Crypto Comparison" $false "API returned success=false"
            return $false
        }
    } catch {
        Write-TestResult "Crypto Comparison" $false $_.Exception.Message
        return $false
    }
}

function Test-Recommendations {
    Write-Host "`n💰 Testing Investment Recommendations..." -ForegroundColor Cyan
    
    try {
        $body = @{
            risk_tolerance = "medium"
            investment_type = "long_term"
            budget_range = 10000
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$AIBaseUrl/crypto/recommend" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        
        if ($response.success) {
            $recCount = $response.data.recommended_cryptocurrencies.Count
            $strategyLength = $response.data.investment_strategy.Length
            Write-TestResult "Investment Recommendations" $true "$recCount recommendations, Strategy: $strategyLength chars"
            return $true
        } else {
            Write-TestResult "Investment Recommendations" $false "API returned success=false"
            return $false
        }
    } catch {
        Write-TestResult "Investment Recommendations" $false $_.Exception.Message
        return $false
    }
}

# Main execution
Write-Host "🚀 Starting Enhanced AI Features Test Suite" -ForegroundColor Magenta
Write-Host "=" * 50 -ForegroundColor Magenta

# Check if server is running
try {
    $healthCheck = Invoke-RestMethod -Uri "$BaseUrl/actuator/health" -Method Get -TimeoutSec 5
    if (-not $healthCheck) {
        Write-Host "❌ Server is not running or not healthy" -ForegroundColor Red
        Write-Host "   Make sure the application is running on $BaseUrl" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "❌ Cannot connect to server: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Make sure the application is running on $BaseUrl" -ForegroundColor Yellow
    exit 1
}

# Run tests
$testResults = @()
$testResults += @{ Name = "AI Health"; Result = Test-AIHealth }
$testResults += @{ Name = "Crypto Q&A"; Result = Test-CryptoQA }
$testResults += @{ Name = "General Q&A"; Result = Test-GeneralQA }
$testResults += @{ Name = "Similar Coins"; Result = Test-SimilarCoins }
$testResults += @{ Name = "Comparison"; Result = Test-Comparison }
$testResults += @{ Name = "Recommendations"; Result = Test-Recommendations }

# Summary
Write-Host "`n$('=' * 50)" -ForegroundColor Magenta
Write-Host "📊 Test Results Summary" -ForegroundColor Magenta
Write-Host "=" * 50 -ForegroundColor Magenta

$passed = 0
$total = $testResults.Count

foreach ($test in $testResults) {
    $status = if ($test.Result) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($test.Result) { "Green" } else { "Red" }
    Write-Host ("{0,-20} {1}" -f $test.Name, $status) -ForegroundColor $color
    if ($test.Result) { $passed++ }
}

Write-Host ("-" * 50) -ForegroundColor Gray
Write-Host "Overall Result: $passed/$total tests passed" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })

if ($passed -eq $total) {
    Write-Host "🎉 All tests passed! AI features are working perfectly!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some tests failed. Check the results above for details." -ForegroundColor Yellow
}

# Usage examples
Write-Host "`n📚 Usage Examples:" -ForegroundColor Cyan
Write-Host "  Test AI Health: Invoke-RestMethod '$AIBaseUrl/health'" -ForegroundColor Gray
Write-Host "  Ask Bitcoin Q&A: Invoke-RestMethod '$AIBaseUrl/crypto/question/BTC' -Method Post -Body '{`"question`":`"Should I invest?`"}' -ContentType 'application/json'" -ForegroundColor Gray
Write-Host "  Find Similar to ETH: Invoke-RestMethod '$AIBaseUrl/crypto/similar/ETH?limit=5'" -ForegroundColor Gray

exit $(if ($passed -eq $total) { 0 } else { 1 })
