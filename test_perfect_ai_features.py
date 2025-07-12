#!/usr/bin/env python3
"""
Perfect AI Features Test Script - Comprehensive testing of all AI capabilities
Tests both enhanced and perfect AI Q&A and similar coin features
"""

import requests
import json
import time
from datetime import datetime
import sys
import concurrent.futures
import threading

# Configuration
BASE_URL = "http://localhost:8080"
ENHANCED_AI_URL = f"{BASE_URL}/api/v1/ai"
PERFECT_AI_URL = f"{BASE_URL}/api/v1/perfect-ai"

# Test counters
total_tests = 0
passed_tests = 0
failed_tests = 0
test_results = []

# Thread-safe printing
print_lock = threading.Lock()

def safe_print(*args, **kwargs):
    with print_lock:
        print(*args, **kwargs)

def log_test_result(test_name, success, response_time=None, error=None):
    global total_tests, passed_tests, failed_tests
    total_tests += 1
    
    if success:
        passed_tests += 1
        status = "✅ PASS"
        color = "\033[92m"
    else:
        failed_tests += 1
        status = "❌ FAIL"
        color = "\033[91m"
    
    reset_color = "\033[0m"
    
    result = {
        "test": test_name,
        "success": success,
        "response_time": response_time,
        "error": error,
        "timestamp": datetime.now().isoformat()
    }
    test_results.append(result)
    
    time_str = f" ({response_time:.2f}s)" if response_time else ""
    error_str = f" - {error}" if error else ""
    
    safe_print(f"{color}{status}{reset_color} {test_name}{time_str}{error_str}")

def test_api_endpoint(url, method='GET', data=None, test_name=None):
    """Test a single API endpoint"""
    start_time = time.time()
    
    try:
        if method == 'GET':
            response = requests.get(url, timeout=30)
        elif method == 'POST':
            response = requests.post(url, json=data, timeout=30)
        else:
            raise ValueError(f"Unsupported method: {method}")
        
        response_time = time.time() - start_time
        
        if response.status_code == 200:
            try:
                json_response = response.json()
                if json_response.get('success'):
                    log_test_result(test_name, True, response_time)
                    return json_response
                else:
                    log_test_result(test_name, False, response_time, json_response.get('message'))
                    return None
            except json.JSONDecodeError:
                log_test_result(test_name, False, response_time, "Invalid JSON response")
                return None
        else:
            log_test_result(test_name, False, response_time, f"HTTP {response.status_code}")
            return None
            
    except requests.exceptions.Timeout:
        log_test_result(test_name, False, 30.0, "Request timeout")
        return None
    except requests.exceptions.ConnectionError:
        log_test_result(test_name, False, None, "Connection error")
        return None
    except Exception as e:
        log_test_result(test_name, False, None, str(e))
        return None

def test_enhanced_ai_qa():
    """Test Enhanced AI Q&A Service"""
    safe_print("\n🧠 Testing Enhanced AI Q&A Service...")
    
    # Test crypto-specific questions
    crypto_questions = [
        ("BTC", "What is the current market outlook for Bitcoin?"),
        ("ETH", "Is Ethereum a good investment right now?"),
        ("ADA", "What are the key risks of investing in Cardano?"),
        ("SOL", "How does Solana compare to Ethereum?"),
        ("DOT", "What's the technology behind Polkadot?")
    ]
    
    def test_crypto_qa(symbol, question):
        url = f"{ENHANCED_AI_URL}/crypto/question/{symbol}"
        data = {"question": question}
        return test_api_endpoint(url, 'POST', data, f"Enhanced AI Q&A - {symbol}")
    
    # Test in parallel
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        futures = [executor.submit(test_crypto_qa, symbol, question) 
                  for symbol, question in crypto_questions]
        
        for future in concurrent.futures.as_completed(futures):
            future.result()
    
    # Test general questions
    general_questions = [
        "What is cryptocurrency?",
        "How does blockchain technology work?",
        "What is DeFi?",
        "What are the risks of cryptocurrency investment?"
    ]
    
    def test_general_qa(question):
        url = f"{ENHANCED_AI_URL}/question/general"
        data = {"question": question}
        return test_api_endpoint(url, 'POST', data, f"Enhanced AI General Q&A")
    
    for question in general_questions:
        test_general_qa(question)
        time.sleep(0.5)

def test_perfect_ai_qa():
    """Test Perfect AI Q&A Service"""
    safe_print("\n🤖 Testing Perfect AI Q&A Service...")
    
    # Test crypto-specific questions with perfect AI
    crypto_questions = [
        ("BTC", "Provide a comprehensive analysis of Bitcoin's current market position"),
        ("ETH", "What are the long-term prospects for Ethereum?"),
        ("ADA", "Compare Cardano's technology to other smart contract platforms"),
        ("SOL", "What factors are driving Solana's adoption?"),
        ("AVAX", "Analyze Avalanche's competitive advantages")
    ]
    
    def test_perfect_crypto_qa(symbol, question):
        url = f"{PERFECT_AI_URL}/crypto/question/{symbol}"
        data = {
            "question": question,
            "context": "Investment analysis context",
            "language": "en"
        }
        return test_api_endpoint(url, 'POST', data, f"Perfect AI Q&A - {symbol}")
    
    # Test in parallel
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        futures = [executor.submit(test_perfect_crypto_qa, symbol, question) 
                  for symbol, question in crypto_questions]
        
        for future in concurrent.futures.as_completed(futures):
            future.result()
    
    # Test general questions with perfect AI
    general_questions = [
        "What's the current state of the cryptocurrency market?",
        "How should beginners approach cryptocurrency investing?",
        "What are the most promising blockchain use cases?",
        "What regulatory challenges does crypto face?"
    ]
    
    def test_perfect_general_qa(question):
        url = f"{PERFECT_AI_URL}/question/general"
        data = {
            "question": question,
            "context": "Educational context",
            "language": "en"
        }
        return test_api_endpoint(url, 'POST', data, f"Perfect AI General Q&A")
    
    for question in general_questions:
        test_perfect_general_qa(question)
        time.sleep(0.5)

def test_enhanced_similar_coins():
    """Test Enhanced Similar Coins Service"""
    safe_print("\n🔍 Testing Enhanced Similar Coins Service...")
    
    symbols = ["BTC", "ETH", "ADA", "SOL", "DOT", "AVAX", "MATIC", "LINK", "UNI", "AAVE"]
    
    def test_similar_coins(symbol):
        url = f"{ENHANCED_AI_URL}/similar/{symbol}?limit=5&includeAnalysis=true&includeMarketData=true"
        return test_api_endpoint(url, 'GET', None, f"Enhanced Similar Coins - {symbol}")
    
    # Test in parallel
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        futures = [executor.submit(test_similar_coins, symbol) for symbol in symbols]
        
        for future in concurrent.futures.as_completed(futures):
            future.result()

def test_perfect_similar_coins():
    """Test Perfect Similar Coins Service"""
    safe_print("\n🎯 Testing Perfect Similar Coins Service...")
    
    symbols = ["BTC", "ETH", "ADA", "SOL", "DOT", "AVAX", "MATIC", "LINK", "UNI", "AAVE"]
    
    def test_perfect_similar_coins(symbol):
        url = f"{PERFECT_AI_URL}/similar/{symbol}?limit=8&includeAIAnalysis=true&includeMarketData=true&analysisDepth=deep"
        return test_api_endpoint(url, 'GET', None, f"Perfect Similar Coins - {symbol}")
    
    # Test in parallel
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        futures = [executor.submit(test_perfect_similar_coins, symbol) for symbol in symbols]
        
        for future in concurrent.futures.as_completed(futures):
            future.result()

def test_ai_comparisons():
    """Test AI-powered coin comparisons"""
    safe_print("\n⚖️ Testing AI-powered Coin Comparisons...")
    
    comparisons = [
        ("BTC", "ETH", "comprehensive"),
        ("ADA", "SOL", "technical"),
        ("DOT", "AVAX", "investment"),
        ("MATIC", "LINK", "market"),
        ("UNI", "AAVE", "defi")
    ]
    
    def test_comparison(symbol1, symbol2, comp_type):
        # Test enhanced comparison
        url = f"{ENHANCED_AI_URL}/compare"
        data = {
            "symbol1": symbol1,
            "symbol2": symbol2,
            "comparison_type": comp_type,
            "include_market_data": True
        }
        test_api_endpoint(url, 'POST', data, f"Enhanced AI Comparison - {symbol1} vs {symbol2}")
        
        # Test perfect comparison
        url = f"{PERFECT_AI_URL}/compare"
        data = {
            "symbol1": symbol1,
            "symbol2": symbol2,
            "comparison_type": comp_type,
            "include_market_data": True
        }
        test_api_endpoint(url, 'POST', data, f"Perfect AI Comparison - {symbol1} vs {symbol2}")
    
    for symbol1, symbol2, comp_type in comparisons:
        test_comparison(symbol1, symbol2, comp_type)
        time.sleep(0.5)

def test_personalized_recommendations():
    """Test personalized cryptocurrency recommendations"""
    safe_print("\n💡 Testing Personalized Recommendations...")
    
    # Test enhanced recommendations
    url = f"{ENHANCED_AI_URL}/recommendations/personalized"
    data = {
        "preferences": {
            "risk_tolerance": "medium",
            "investment_goal": "growth",
            "time_horizon": "long",
            "categories": ["defi", "smart-contracts"],
            "max_price": 1000.0
        },
        "limit": 8,
        "include_ai_analysis": True
    }
    test_api_endpoint(url, 'POST', data, "Enhanced Personalized Recommendations")
    
    # Test perfect recommendations
    url = f"{PERFECT_AI_URL}/recommendations/personalized"
    data = {
        "preferences": {
            "risk_tolerance": "high",
            "investment_goal": "speculation",
            "time_horizon": "short",
            "categories": ["layer-2", "defi"],
            "max_price": 500.0
        },
        "limit": 10,
        "include_ai_analysis": True
    }
    test_api_endpoint(url, 'POST', data, "Perfect Personalized Recommendations")

def test_advanced_features():
    """Test advanced AI features"""
    safe_print("\n🚀 Testing Advanced AI Features...")
    
    # Test bulk analysis
    url = f"{PERFECT_AI_URL}/bulk/analysis"
    data = {
        "symbols": ["BTC", "ETH", "ADA", "SOL", "DOT"],
        "question": "What are the key strengths and weaknesses of this cryptocurrency?",
        "context": "Investment research",
        "language": "en"
    }
    test_api_endpoint(url, 'POST', data, "Perfect Bulk AI Analysis")
    
    # Test market sentiment
    url = f"{PERFECT_AI_URL}/market/sentiment?marketSegment=defi&analysisType=comprehensive"
    test_api_endpoint(url, 'GET', None, "Perfect Market Sentiment Analysis")
    
    # Test portfolio optimization
    url = f"{PERFECT_AI_URL}/portfolio/optimize"
    data = {
        "portfolio": [
            {"symbol": "BTC", "value": 5000, "category": "store-of-value"},
            {"symbol": "ETH", "value": 3000, "category": "smart-contracts"},
            {"symbol": "ADA", "value": 1000, "category": "smart-contracts"}
        ],
        "goals": {"objective": "growth", "timeframe": "long"},
        "risk_tolerance": "medium"
    }
    test_api_endpoint(url, 'POST', data, "Perfect Portfolio Optimization")
    
    # Test trending insights
    url = f"{PERFECT_AI_URL}/trending/insights?limit=10&includeAIAnalysis=true"
    test_api_endpoint(url, 'GET', None, "Perfect Trending Insights")

def test_health_checks():
    """Test service health checks"""
    safe_print("\n🔍 Testing Service Health Checks...")
    
    # Test enhanced AI health
    url = f"{ENHANCED_AI_URL}/health"
    test_api_endpoint(url, 'GET', None, "Enhanced AI Health Check")
    
    # Test perfect AI health
    url = f"{PERFECT_AI_URL}/health"
    test_api_endpoint(url, 'GET', None, "Perfect AI Health Check")

def test_performance_and_caching():
    """Test performance and caching behavior"""
    safe_print("\n⚡ Testing Performance and Caching...")
    
    # Test repeated requests to verify caching
    symbol = "BTC"
    question = "What is the current market outlook?"
    
    # First request (should hit AI service)
    url = f"{PERFECT_AI_URL}/crypto/question/{symbol}"
    data = {"question": question}
    
    start_time = time.time()
    response1 = test_api_endpoint(url, 'POST', data, "Perfect AI Q&A - First Request")
    first_response_time = time.time() - start_time
    
    # Second request (should hit cache)
    start_time = time.time()
    response2 = test_api_endpoint(url, 'POST', data, "Perfect AI Q&A - Cached Request")
    cached_response_time = time.time() - start_time
    
    # Verify caching worked (cached request should be faster)
    if cached_response_time < first_response_time:
        log_test_result("Caching Performance Improvement", True, cached_response_time)
    else:
        log_test_result("Caching Performance Improvement", False, cached_response_time, "Cache not working effectively")
    
    # Test similar coins caching
    url = f"{PERFECT_AI_URL}/similar/{symbol}?limit=5&includeAIAnalysis=true"
    
    start_time = time.time()
    test_api_endpoint(url, 'GET', None, "Perfect Similar Coins - First Request")
    first_similar_time = time.time() - start_time
    
    start_time = time.time()
    test_api_endpoint(url, 'GET', None, "Perfect Similar Coins - Cached Request")
    cached_similar_time = time.time() - start_time
    
    if cached_similar_time < first_similar_time:
        log_test_result("Similar Coins Caching Performance", True, cached_similar_time)
    else:
        log_test_result("Similar Coins Caching Performance", False, cached_similar_time, "Cache not working effectively")

def print_test_summary():
    """Print comprehensive test summary"""
    safe_print("\n" + "="*80)
    safe_print("🎯 PERFECT AI FEATURES TEST SUMMARY")
    safe_print("="*80)
    
    success_rate = (passed_tests / total_tests * 100) if total_tests > 0 else 0
    
    safe_print(f"Total Tests: {total_tests}")
    safe_print(f"Passed: \033[92m{passed_tests}\033[0m")
    safe_print(f"Failed: \033[91m{failed_tests}\033[0m")
    safe_print(f"Success Rate: {'🟢' if success_rate >= 80 else '🟡' if success_rate >= 60 else '🔴'} {success_rate:.1f}%")
    
    if failed_tests > 0:
        safe_print(f"\n❌ FAILED TESTS ({failed_tests}):")
        for result in test_results:
            if not result['success']:
                safe_print(f"  - {result['test']}: {result['error']}")
    
    # Calculate performance metrics
    successful_tests = [r for r in test_results if r['success'] and r['response_time']]
    if successful_tests:
        avg_response_time = sum(r['response_time'] for r in successful_tests) / len(successful_tests)
        max_response_time = max(r['response_time'] for r in successful_tests)
        min_response_time = min(r['response_time'] for r in successful_tests)
        
        safe_print(f"\n📊 PERFORMANCE METRICS:")
        safe_print(f"Average Response Time: {avg_response_time:.2f}s")
        safe_print(f"Fastest Response: {min_response_time:.2f}s")
        safe_print(f"Slowest Response: {max_response_time:.2f}s")
    
    # Overall assessment
    safe_print(f"\n🎉 OVERALL ASSESSMENT:")
    if success_rate >= 95:
        safe_print("🏆 EXCELLENT - Perfect AI features working flawlessly!")
    elif success_rate >= 85:
        safe_print("✅ GOOD - Perfect AI features working well with minor issues")
    elif success_rate >= 70:
        safe_print("⚠️ ACCEPTABLE - Perfect AI features working with some problems")
    else:
        safe_print("❌ NEEDS ATTENTION - Perfect AI features have significant issues")
    
    safe_print("="*80)

def main():
    """Main test execution"""
    safe_print("🚀 Starting Perfect AI Features Comprehensive Test Suite")
    safe_print("="*80)
    
    start_time = time.time()
    
    try:
        # Test all components
        test_health_checks()
        test_enhanced_ai_qa()
        test_perfect_ai_qa()
        test_enhanced_similar_coins()
        test_perfect_similar_coins()
        test_ai_comparisons()
        test_personalized_recommendations()
        test_advanced_features()
        test_performance_and_caching()
        
    except KeyboardInterrupt:
        safe_print("\n⏹️ Test execution interrupted by user")
        return 1
    except Exception as e:
        safe_print(f"\n💥 Unexpected error during testing: {e}")
        return 1
    finally:
        total_time = time.time() - start_time
        safe_print(f"\n⏱️ Total Test Execution Time: {total_time:.2f} seconds")
        print_test_summary()
        
        # Save detailed results
        with open("perfect_ai_test_results.json", "w") as f:
            json.dump({
                "summary": {
                    "total_tests": total_tests,
                    "passed_tests": passed_tests,
                    "failed_tests": failed_tests,
                    "success_rate": (passed_tests / total_tests * 100) if total_tests > 0 else 0,
                    "total_time": total_time
                },
                "results": test_results
            }, f, indent=2)
        
        safe_print(f"\n📄 Detailed results saved to: perfect_ai_test_results.json")
    
    return 0 if failed_tests == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
