# Perfect AI Features Test Script - PowerShell Version
# Comprehensive testing of all AI capabilities

param(
    [string]$BaseUrl = "http://localhost:8080",
    [int]$TimeoutSeconds = 30,
    [switch]$Verbose
)

# Configuration
$EnhancedAIUrl = "$BaseUrl/api/v1/ai"
$PerfectAIUrl = "$BaseUrl/api/v1/perfect-ai"

# Test counters
$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0
$script:TestResults = @()

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$White = "White"
$Cyan = "Cyan"

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Success,
        [double]$ResponseTime = 0,
        [string]$Error = ""
    )
    
    $script:TotalTests++
    
    if ($Success) {
        $script:PassedTests++
        $Status = "✅ PASS"
        $Color = $Green
    } else {
        $script:FailedTests++
        $Status = "❌ FAIL"
        $Color = $Red
    }
    
    $Result = [PSCustomObject]@{
        Test = $TestName
        Success = $Success
        ResponseTime = $ResponseTime
        Error = $Error
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    $script:TestResults += $Result
    
    $TimeStr = if ($ResponseTime -gt 0) { " ($([math]::Round($ResponseTime, 2))s)" } else { "" }
    $ErrorStr = if ($Error) { " - $Error" } else { "" }
    
    Write-Host "$Status $TestName$TimeStr$ErrorStr" -ForegroundColor $Color
}

function Test-ApiEndpoint {
    param(
        [string]$Url,
        [string]$Method = "GET",
        [hashtable]$Data = $null,
        [string]$TestName
    )
    
    $StartTime = Get-Date
    
    try {
        $Headers = @{
            "Content-Type" = "application/json"
            "Accept" = "application/json"
        }
        
        $SplatParams = @{
            Uri = $Url
            Method = $Method
            Headers = $Headers
            TimeoutSec = $TimeoutSeconds
        }
        
        if ($Data -and $Method -eq "POST") {
            $SplatParams.Body = $Data | ConvertTo-Json -Depth 10
        }
        
        $Response = Invoke-RestMethod @SplatParams
        $ResponseTime = ((Get-Date) - $StartTime).TotalSeconds
        
        if ($Response.success) {
            Write-TestResult -TestName $TestName -Success $true -ResponseTime $ResponseTime
            return $Response
        } else {
            Write-TestResult -TestName $TestName -Success $false -ResponseTime $ResponseTime -Error $Response.message
            return $null
        }
        
    } catch {
        $ResponseTime = ((Get-Date) - $StartTime).TotalSeconds
        $ErrorMessage = $_.Exception.Message
        
        if ($_.Exception -is [System.Net.WebException]) {
            $ErrorMessage = "Network error: $ErrorMessage"
        }
        
        Write-TestResult -TestName $TestName -Success $false -ResponseTime $ResponseTime -Error $ErrorMessage
        return $null
    }
}

function Test-EnhancedAIQA {
    Write-Host "`n🧠 Testing Enhanced AI Q&A Service..." -ForegroundColor $Cyan
    
    # Test crypto-specific questions
    $CryptoQuestions = @(
        @{ Symbol = "BTC"; Question = "What is the current market outlook for Bitcoin?" },
        @{ Symbol = "ETH"; Question = "Is Ethereum a good investment right now?" },
        @{ Symbol = "ADA"; Question = "What are the key risks of investing in Cardano?" },
        @{ Symbol = "SOL"; Question = "How does Solana compare to Ethereum?" },
        @{ Symbol = "DOT"; Question = "What's the technology behind Polkadot?" }
    )
    
    foreach ($Item in $CryptoQuestions) {
        $Url = "$EnhancedAIUrl/crypto/question/$($Item.Symbol)"
        $Data = @{ question = $Item.Question }
        Test-ApiEndpoint -Url $Url -Method "POST" -Data $Data -TestName "Enhanced AI Q&A - $($Item.Symbol)"
        Start-Sleep -Milliseconds 500
    }
    
    # Test general questions
    $GeneralQuestions = @(
        "What is cryptocurrency?",
        "How does blockchain technology work?",
        "What is DeFi?",
        "What are the risks of cryptocurrency investment?"
    )
    
    foreach ($Question in $GeneralQuestions) {
        $Url = "$EnhancedAIUrl/question/general"
        $Data = @{ question = $Question }
        Test-ApiEndpoint -Url $Url -Method "POST" -Data $Data -TestName "Enhanced AI General Q&A"
        Start-Sleep -Milliseconds 500
    }
}

function Test-PerfectAIQA {
    Write-Host "`n🤖 Testing Perfect AI Q&A Service..." -ForegroundColor $Cyan
    
    # Test crypto-specific questions with perfect AI
    $CryptoQuestions = @(
        @{ Symbol = "BTC"; Question = "Provide a comprehensive analysis of Bitcoin's current market position" },
        @{ Symbol = "ETH"; Question = "What are the long-term prospects for Ethereum?" },
        @{ Symbol = "ADA"; Question = "Compare Cardano's technology to other smart contract platforms" },
        @{ Symbol = "SOL"; Question = "What factors are driving Solana's adoption?" },
        @{ Symbol = "AVAX"; Question = "Analyze Avalanche's competitive advantages" }
    )
    
    foreach ($Item in $CryptoQuestions) {
        $Url = "$PerfectAIUrl/crypto/question/$($Item.Symbol)"
        $Data = @{
            question = $Item.Question
            context = "Investment analysis context"
            language = "en"
        }
        Test-ApiEndpoint -Url $Url -Method "POST" -Data $Data -TestName "Perfect AI Q&A - $($Item.Symbol)"
        Start-Sleep -Milliseconds 500
    }
    
    # Test general questions with perfect AI
    $GeneralQuestions = @(
        "What's the current state of the cryptocurrency market?",
        "How should beginners approach cryptocurrency investing?",
        "What are the most promising blockchain use cases?",
        "What regulatory challenges does crypto face?"
    )
    
    foreach ($Question in $GeneralQuestions) {
        $Url = "$PerfectAIUrl/question/general"
        $Data = @{
            question = $Question
            context = "Educational context"
            language = "en"
        }
        Test-ApiEndpoint -Url $Url -Method "POST" -Data $Data -TestName "Perfect AI General Q&A"
        Start-Sleep -Milliseconds 500
    }
}

function Test-EnhancedSimilarCoins {
    Write-Host "`n🔍 Testing Enhanced Similar Coins Service..." -ForegroundColor $Cyan
    
    $Symbols = @("BTC", "ETH", "ADA", "SOL", "DOT", "AVAX", "MATIC", "LINK", "UNI", "AAVE")
    
    foreach ($Symbol in $Symbols) {
        $Url = "$EnhancedAIUrl/similar/$Symbol" + "?limit=5&includeAnalysis=true&includeMarketData=true"
        Test-ApiEndpoint -Url $Url -Method "GET" -TestName "Enhanced Similar Coins - $Symbol"
        Start-Sleep -Milliseconds 300
    }
}

function Test-PerfectSimilarCoins {
    Write-Host "`n🎯 Testing Perfect Similar Coins Service..." -ForegroundColor $Cyan
    
    $Symbols = @("BTC", "ETH", "ADA", "SOL", "DOT", "AVAX", "MATIC", "LINK", "UNI", "AAVE")
    
    foreach ($Symbol in $Symbols) {
        $Url = "$PerfectAIUrl/similar/$Symbol" + "?limit=8&includeAIAnalysis=true&includeMarketData=true&analysisDepth=deep"
        Test-ApiEndpoint -Url $Url -Method "GET" -TestName "Perfect Similar Coins - $Symbol"
        Start-Sleep -Milliseconds 400
    }
}

function Test-AIComparisons {
    Write-Host "`n⚖️ Testing AI-powered Coin Comparisons..." -ForegroundColor $Cyan
    
    $Comparisons = @(
        @{ Symbol1 = "BTC"; Symbol2 = "ETH"; Type = "comprehensive" },
        @{ Symbol1 = "ADA"; Symbol2 = "SOL"; Type = "technical" },
        @{ Symbol1 = "DOT"; Symbol2 = "AVAX"; Type = "investment" },
        @{ Symbol1 = "MATIC"; Symbol2 = "LINK"; Type = "market" },
        @{ Symbol1 = "UNI"; Symbol2 = "AAVE"; Type = "defi" }
    )
    
    foreach ($Comparison in $Comparisons) {
        # Test enhanced comparison
        $Url = "$EnhancedAIUrl/compare"
        $Data = @{
            symbol1 = $Comparison.Symbol1
            symbol2 = $Comparison.Symbol2
            comparison_type = $Comparison.Type
            include_market_data = $true
        }
        Test-ApiEndpoint -Url $Url -Method "POST" -Data $Data -TestName "Enhanced AI Comparison - $($Comparison.Symbol1) vs $($Comparison.Symbol2)"
        
        # Test perfect comparison
        $Url = "$PerfectAIUrl/compare"
        Test-ApiEndpoint -Url $Url -Method "POST" -Data $Data -TestName "Perfect AI Comparison - $($Comparison.Symbol1) vs $($Comparison.Symbol2)"
        
        Start-Sleep -Milliseconds 500
    }
}

function Test-PersonalizedRecommendations {
    Write-Host "`n💡 Testing Personalized Recommendations..." -ForegroundColor $Cyan
    
    # Test enhanced recommendations
    $Url = "$EnhancedAIUrl/recommendations/personalized"
    $Data = @{
        preferences = @{
            risk_tolerance = "medium"
            investment_goal = "growth"
            time_horizon = "long"
            categories = @("defi", "smart-contracts")
            max_price = 1000.0
        }
        limit = 8
        include_ai_analysis = $true
    }
    Test-ApiEndpoint -Url $Url -Method "POST" -Data $Data -TestName "Enhanced Personalized Recommendations"
    
    # Test perfect recommendations
    $Url = "$PerfectAIUrl/recommendations/personalized"
    $Data = @{
        preferences = @{
            risk_tolerance = "high"
            investment_goal = "speculation"
            time_horizon = "short"
            categories = @("layer-2", "defi")
            max_price = 500.0
        }
        limit = 10
        include_ai_analysis = $true
    }
    Test-ApiEndpoint -Url $Url -Method "POST" -Data $Data -TestName "Perfect Personalized Recommendations"
}

function Test-AdvancedFeatures {
    Write-Host "`n🚀 Testing Advanced AI Features..." -ForegroundColor $Cyan
    
    # Test bulk analysis
    $Url = "$PerfectAIUrl/bulk/analysis"
    $Data = @{
        symbols = @("BTC", "ETH", "ADA", "SOL", "DOT")
        question = "What are the key strengths and weaknesses of this cryptocurrency?"
        context = "Investment research"
        language = "en"
    }
    Test-ApiEndpoint -Url $Url -Method "POST" -Data $Data -TestName "Perfect Bulk AI Analysis"
    
    # Test market sentiment
    $Url = "$PerfectAIUrl/market/sentiment?marketSegment=defi&analysisType=comprehensive"
    Test-ApiEndpoint -Url $Url -Method "GET" -TestName "Perfect Market Sentiment Analysis"
    
    # Test portfolio optimization
    $Url = "$PerfectAIUrl/portfolio/optimize"
    $Data = @{
        portfolio = @(
            @{ symbol = "BTC"; value = 5000; category = "store-of-value" },
            @{ symbol = "ETH"; value = 3000; category = "smart-contracts" },
            @{ symbol = "ADA"; value = 1000; category = "smart-contracts" }
        )
        goals = @{ objective = "growth"; timeframe = "long" }
        risk_tolerance = "medium"
    }
    Test-ApiEndpoint -Url $Url -Method "POST" -Data $Data -TestName "Perfect Portfolio Optimization"
    
    # Test trending insights
    $Url = "$PerfectAIUrl/trending/insights?limit=10&includeAIAnalysis=true"
    Test-ApiEndpoint -Url $Url -Method "GET" -TestName "Perfect Trending Insights"
}

function Test-HealthChecks {
    Write-Host "`n🔍 Testing Service Health Checks..." -ForegroundColor $Cyan
    
    # Test enhanced AI health
    $Url = "$EnhancedAIUrl/health"
    Test-ApiEndpoint -Url $Url -Method "GET" -TestName "Enhanced AI Health Check"
    
    # Test perfect AI health
    $Url = "$PerfectAIUrl/health"
    Test-ApiEndpoint -Url $Url -Method "GET" -TestName "Perfect AI Health Check"
}

function Test-PerformanceAndCaching {
    Write-Host "`n⚡ Testing Performance and Caching..." -ForegroundColor $Cyan
    
    # Test repeated requests to verify caching
    $Symbol = "BTC"
    $Question = "What is the current market outlook?"
    
    # First request (should hit AI service)
    $Url = "$PerfectAIUrl/crypto/question/$Symbol"
    $Data = @{ question = $Question }
    
    $StartTime = Get-Date
    $Response1 = Test-ApiEndpoint -Url $Url -Method "POST" -Data $Data -TestName "Perfect AI Q&A - First Request"
    $FirstResponseTime = ((Get-Date) - $StartTime).TotalSeconds
    
    # Second request (should hit cache)
    $StartTime = Get-Date
    $Response2 = Test-ApiEndpoint -Url $Url -Method "POST" -Data $Data -TestName "Perfect AI Q&A - Cached Request"
    $CachedResponseTime = ((Get-Date) - $StartTime).TotalSeconds
    
    # Verify caching worked
    if ($CachedResponseTime -lt $FirstResponseTime) {
        Write-TestResult -TestName "Caching Performance Improvement" -Success $true -ResponseTime $CachedResponseTime
    } else {
        Write-TestResult -TestName "Caching Performance Improvement" -Success $false -ResponseTime $CachedResponseTime -Error "Cache not working effectively"
    }
    
    # Test similar coins caching
    $Url = "$PerfectAIUrl/similar/$Symbol" + "?limit=5&includeAIAnalysis=true"
    
    $StartTime = Get-Date
    Test-ApiEndpoint -Url $Url -Method "GET" -TestName "Perfect Similar Coins - First Request"
    $FirstSimilarTime = ((Get-Date) - $StartTime).TotalSeconds
    
    $StartTime = Get-Date
    Test-ApiEndpoint -Url $Url -Method "GET" -TestName "Perfect Similar Coins - Cached Request"
    $CachedSimilarTime = ((Get-Date) - $StartTime).TotalSeconds
    
    if ($CachedSimilarTime -lt $FirstSimilarTime) {
        Write-TestResult -TestName "Similar Coins Caching Performance" -Success $true -ResponseTime $CachedSimilarTime
    } else {
        Write-TestResult -TestName "Similar Coins Caching Performance" -Success $false -ResponseTime $CachedSimilarTime -Error "Cache not working effectively"
    }
}

function Write-TestSummary {
    Write-Host "`n" -NoNewline
    Write-Host ("=" * 80) -ForegroundColor $White
    Write-Host "🎯 PERFECT AI FEATURES TEST SUMMARY" -ForegroundColor $Cyan
    Write-Host ("=" * 80) -ForegroundColor $White
    
    $SuccessRate = if ($script:TotalTests -gt 0) { ($script:PassedTests / $script:TotalTests * 100) } else { 0 }
    
    Write-Host "Total Tests: $($script:TotalTests)" -ForegroundColor $White
    Write-Host "Passed: $($script:PassedTests)" -ForegroundColor $Green
    Write-Host "Failed: $($script:FailedTests)" -ForegroundColor $Red
    
    $RateColor = if ($SuccessRate -ge 80) { $Green } elseif ($SuccessRate -ge 60) { $Yellow } else { $Red }
    $RateIcon = if ($SuccessRate -ge 80) { "🟢" } elseif ($SuccessRate -ge 60) { "🟡" } else { "🔴" }
    Write-Host "Success Rate: $RateIcon $([math]::Round($SuccessRate, 1))%" -ForegroundColor $RateColor
    
    if ($script:FailedTests -gt 0) {
        Write-Host "`n❌ FAILED TESTS ($($script:FailedTests)):" -ForegroundColor $Red
        foreach ($Result in $script:TestResults) {
            if (-not $Result.Success) {
                Write-Host "  - $($Result.Test): $($Result.Error)" -ForegroundColor $Red
            }
        }
    }
    
    # Calculate performance metrics
    $SuccessfulTests = $script:TestResults | Where-Object { $_.Success -and $_.ResponseTime -gt 0 }
    if ($SuccessfulTests) {
        $AvgResponseTime = ($SuccessfulTests | Measure-Object -Property ResponseTime -Average).Average
        $MaxResponseTime = ($SuccessfulTests | Measure-Object -Property ResponseTime -Maximum).Maximum
        $MinResponseTime = ($SuccessfulTests | Measure-Object -Property ResponseTime -Minimum).Minimum
        
        Write-Host "`n📊 PERFORMANCE METRICS:" -ForegroundColor $Cyan
        Write-Host "Average Response Time: $([math]::Round($AvgResponseTime, 2))s" -ForegroundColor $White
        Write-Host "Fastest Response: $([math]::Round($MinResponseTime, 2))s" -ForegroundColor $White
        Write-Host "Slowest Response: $([math]::Round($MaxResponseTime, 2))s" -ForegroundColor $White
    }
    
    # Overall assessment
    Write-Host "`n🎉 OVERALL ASSESSMENT:" -ForegroundColor $Cyan
    if ($SuccessRate -ge 95) {
        Write-Host "🏆 EXCELLENT - Perfect AI features working flawlessly!" -ForegroundColor $Green
    } elseif ($SuccessRate -ge 85) {
        Write-Host "✅ GOOD - Perfect AI features working well with minor issues" -ForegroundColor $Green
    } elseif ($SuccessRate -ge 70) {
        Write-Host "⚠️ ACCEPTABLE - Perfect AI features working with some problems" -ForegroundColor $Yellow
    } else {
        Write-Host "❌ NEEDS ATTENTION - Perfect AI features have significant issues" -ForegroundColor $Red
    }
    
    Write-Host ("=" * 80) -ForegroundColor $White
}

# Main execution
Write-Host "🚀 Starting Perfect AI Features Comprehensive Test Suite" -ForegroundColor $Cyan
Write-Host ("=" * 80) -ForegroundColor $White

$StartTime = Get-Date

try {
    # Test all components
    Test-HealthChecks
    Test-EnhancedAIQA
    Test-PerfectAIQA
    Test-EnhancedSimilarCoins
    Test-PerfectSimilarCoins
    Test-AIComparisons
    Test-PersonalizedRecommendations
    Test-AdvancedFeatures
    Test-PerformanceAndCaching
    
} catch {
    Write-Host "`n💥 Unexpected error during testing: $($_.Exception.Message)" -ForegroundColor $Red
    exit 1
} finally {
    $TotalTime = ((Get-Date) - $StartTime).TotalSeconds
    Write-Host "`n⏱️ Total Test Execution Time: $([math]::Round($TotalTime, 2)) seconds" -ForegroundColor $White
    Write-TestSummary
    
    # Save detailed results
    $Summary = @{
        summary = @{
            total_tests = $script:TotalTests
            passed_tests = $script:PassedTests
            failed_tests = $script:FailedTests
            success_rate = if ($script:TotalTests -gt 0) { ($script:PassedTests / $script:TotalTests * 100) } else { 0 }
            total_time = $TotalTime
        }
        results = $script:TestResults
    }
    
    $Summary | ConvertTo-Json -Depth 10 | Out-File -FilePath "perfect_ai_test_results.json" -Encoding UTF8
    Write-Host "`n📄 Detailed results saved to: perfect_ai_test_results.json" -ForegroundColor $White
}

exit $(if ($script:FailedTests -eq 0) { 0 } else { 1 })
