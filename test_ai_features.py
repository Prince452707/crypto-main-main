#!/usr/bin/env python3
"""
Test script for Enhanced AI Q&A and Similar Coin features
"""

import requests
import json
import time
import sys

# Configuration
BASE_URL = "http://localhost:8080"
AI_BASE_URL = f"{BASE_URL}/api/v1/ai"

def test_ai_health():
    """Test AI service health"""
    print("🔍 Testing AI Service Health...")
    try:
        response = requests.get(f"{AI_BASE_URL}/health")
        if response.status_code == 200:
            data = response.json()
            print("✅ AI Service is operational")
            print(f"   Features: {', '.join(data['data']['features'])}")
            return True
        else:
            print(f"❌ AI Service health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ AI Service health check error: {e}")
        return False

def test_crypto_qa():
    """Test crypto-specific Q&A"""
    print("\n🤖 Testing Crypto-Specific Q&A...")
    
    test_cases = [
        {
            "symbol": "BTC",
            "question": "Should I invest in Bitcoin right now?",
            "expected_type": "INVESTMENT"
        },
        {
            "symbol": "ETH", 
            "question": "What is the price prediction for Ethereum?",
            "expected_type": "PRICE_PREDICTION"
        },
        {
            "symbol": "ADA",
            "question": "What are the risks of investing in Cardano?",
            "expected_type": "RISK_ASSESSMENT"
        }
    ]
    
    success_count = 0
    for i, test_case in enumerate(test_cases, 1):
        print(f"\n  Test {i}: {test_case['symbol']} - {test_case['question'][:50]}...")
        
        try:
            response = requests.post(
                f"{AI_BASE_URL}/crypto/question/{test_case['symbol']}",
                json={"question": test_case["question"]},
                headers={"Content-Type": "application/json"},
                timeout=30
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get("success"):
                    answer_data = data.get("data", {})
                    question_type = answer_data.get("questionType")
                    answer_length = len(answer_data.get("answer", ""))
                    
                    print(f"    ✅ Success - Type: {question_type}, Answer length: {answer_length} chars")
                    if answer_length > 50:  # Reasonable answer length
                        success_count += 1
                    else:
                        print("    ⚠️  Warning: Answer seems too short")
                else:
                    print(f"    ❌ API returned success=false: {data}")
            else:
                print(f"    ❌ HTTP Error {response.status_code}: {response.text}")
                
        except Exception as e:
            print(f"    ❌ Error: {e}")
        
        time.sleep(1)  # Avoid overwhelming the service
    
    print(f"\nCrypto Q&A Results: {success_count}/{len(test_cases)} successful")
    return success_count == len(test_cases)

def test_general_qa():
    """Test general crypto Q&A"""
    print("\n🎓 Testing General Crypto Q&A...")
    
    test_questions = [
        "What is cryptocurrency?",
        "How does blockchain technology work?", 
        "What is DeFi and how does it work?",
        "What are the risks of cryptocurrency investment?"
    ]
    
    success_count = 0
    for i, question in enumerate(test_questions, 1):
        print(f"\n  Test {i}: {question}...")
        
        try:
            response = requests.post(
                f"{AI_BASE_URL}/crypto/question",
                json={"question": question},
                headers={"Content-Type": "application/json"},
                timeout=30
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get("success"):
                    answer_data = data.get("data", {})
                    answer_length = len(answer_data.get("answer", ""))
                    question_type = answer_data.get("questionType")
                    
                    print(f"    ✅ Success - Type: {question_type}, Answer length: {answer_length} chars")
                    if answer_length > 50:
                        success_count += 1
                    else:
                        print("    ⚠️  Warning: Answer seems too short")
                else:
                    print(f"    ❌ API returned success=false: {data}")
            else:
                print(f"    ❌ HTTP Error {response.status_code}: {response.text}")
                
        except Exception as e:
            print(f"    ❌ Error: {e}")
        
        time.sleep(1)
    
    print(f"\nGeneral Q&A Results: {success_count}/{len(test_questions)} successful")
    return success_count == len(test_questions)

def test_similar_coins():
    """Test similar coin recommendations"""
    print("\n🔍 Testing Similar Coin Recommendations...")
    
    test_symbols = ["BTC", "ETH", "ADA", "SOL", "DOGE"]
    
    success_count = 0
    for i, symbol in enumerate(test_symbols, 1):
        print(f"\n  Test {i}: Finding similar coins for {symbol}...")
        
        try:
            response = requests.get(
                f"{AI_BASE_URL}/crypto/similar/{symbol}",
                params={"limit": 5, "includeAnalysis": True, "includeMarketData": False},
                timeout=30
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get("success"):
                    similar_data = data.get("data", {})
                    similar_coins = similar_data.get("similar_cryptocurrencies", [])
                    analysis = similar_data.get("comparison_analysis", "")
                    
                    print(f"    ✅ Success - Found {len(similar_coins)} similar coins")
                    for coin in similar_coins[:3]:  # Show first 3
                        print(f"       • {coin.get('symbol')} (Score: {coin.get('similarity_score')}, Category: {coin.get('category')})")
                    
                    if len(similar_coins) > 0:
                        success_count += 1
                    else:
                        print("    ⚠️  Warning: No similar coins found")
                else:
                    print(f"    ❌ API returned success=false: {data}")
            else:
                print(f"    ❌ HTTP Error {response.status_code}: {response.text}")
                
        except Exception as e:
            print(f"    ❌ Error: {e}")
        
        time.sleep(1)
    
    print(f"\nSimilar Coins Results: {success_count}/{len(test_symbols)} successful")
    return success_count == len(test_symbols)

def test_comparison():
    """Test cryptocurrency comparison"""
    print("\n⚖️  Testing Cryptocurrency Comparison...")
    
    try:
        response = requests.post(
            f"{AI_BASE_URL}/crypto/compare",
            json={"symbols": ["BTC", "ETH", "ADA"]},
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        if response.status_code == 200:
            data = response.json()
            if data.get("success"):
                comparison_data = data.get("data", {})
                analysis = comparison_data.get("analysis", "")
                similarity_matrix = comparison_data.get("similarity_matrix", [])
                
                print(f"    ✅ Success - Analysis length: {len(analysis)} chars")
                print(f"    ✅ Similarity matrix: {len(similarity_matrix)} pairs")
                return True
            else:
                print(f"    ❌ API returned success=false: {data}")
                return False
        else:
            print(f"    ❌ HTTP Error {response.status_code}: {response.text}")
            return False
            
    except Exception as e:
        print(f"    ❌ Error: {e}")
        return False

def test_recommendations():
    """Test investment recommendations"""
    print("\n💰 Testing Investment Recommendations...")
    
    try:
        response = requests.post(
            f"{AI_BASE_URL}/crypto/recommend",
            json={
                "risk_tolerance": "medium",
                "investment_type": "long_term",
                "budget_range": 10000
            },
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        if response.status_code == 200:
            data = response.json()
            if data.get("success"):
                rec_data = data.get("data", {})
                recommended_coins = rec_data.get("recommended_cryptocurrencies", [])
                strategy = rec_data.get("investment_strategy", "")
                
                print(f"    ✅ Success - {len(recommended_coins)} recommendations")
                print(f"    ✅ Strategy length: {len(strategy)} chars")
                return True
            else:
                print(f"    ❌ API returned success=false: {data}")
                return False
        else:
            print(f"    ❌ HTTP Error {response.status_code}: {response.text}")
            return False
            
    except Exception as e:
        print(f"    ❌ Error: {e}")
        return False

def main():
    """Run all tests"""
    print("🚀 Starting Enhanced AI Features Test Suite")
    print("=" * 50)
    
    # Check if server is running
    try:
        response = requests.get(f"{BASE_URL}/actuator/health", timeout=5)
        if response.status_code != 200:
            print("❌ Server is not running or not healthy")
            print(f"   Make sure the application is running on {BASE_URL}")
            sys.exit(1)
    except Exception as e:
        print(f"❌ Cannot connect to server: {e}")
        print(f"   Make sure the application is running on {BASE_URL}")
        sys.exit(1)
    
    # Run tests
    test_results = []
    
    test_results.append(("AI Health", test_ai_health()))
    test_results.append(("Crypto Q&A", test_crypto_qa()))
    test_results.append(("General Q&A", test_general_qa()))
    test_results.append(("Similar Coins", test_similar_coins()))
    test_results.append(("Comparison", test_comparison()))
    test_results.append(("Recommendations", test_recommendations()))
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Results Summary")
    print("=" * 50)
    
    passed = 0
    total = len(test_results)
    
    for test_name, result in test_results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{test_name:<20} {status}")
        if result:
            passed += 1
    
    print("-" * 50)
    print(f"Overall Result: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! AI features are working perfectly!")
        return True
    else:
        print("⚠️  Some tests failed. Check the logs above for details.")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
