#!/usr/bin/env python3
"""
Test script to verify the timeout fixes for the Crypto Insight application.
This script tests the API endpoints to ensure they respond within reasonable time limits.
"""

import requests
import time
import json
from datetime import datetime

BASE_URL = "http://localhost:8081/api/v1"
TIMEOUT_SECONDS = 180  # 3 minutes max for AI analysis

def test_health_check():
    """Test if the backend is running"""
    try:
        response = requests.get(f"http://localhost:8081/actuator/health", timeout=10)
        if response.status_code == 200:
            print("✅ Backend health check: PASSED")
            return True
        else:
            print(f"❌ Backend health check: FAILED (Status: {response.status_code})")
            return False
    except Exception as e:
        print(f"❌ Backend health check: FAILED (Error: {e})")
        return False

def test_market_data():
    """Test market data endpoint"""
    try:
        start_time = time.time()
        response = requests.get(f"{BASE_URL}/crypto/market-data?page=1&perPage=5", timeout=30)
        end_time = time.time()
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Market data test: PASSED ({end_time - start_time:.2f}s)")
            print(f"   Retrieved {len(data.get('data', []))} cryptocurrencies")
            return True
        else:
            print(f"❌ Market data test: FAILED (Status: {response.status_code})")
            return False
    except Exception as e:
        print(f"❌ Market data test: FAILED (Error: {e})")
        return False

def test_crypto_analysis(symbol="BTC", days=30):
    """Test cryptocurrency analysis endpoint"""
    try:
        print(f"\n🔄 Testing AI analysis for {symbol}...")
        start_time = time.time()
        
        response = requests.get(
            f"{BASE_URL}/crypto/analysis/{symbol}/{days}", 
            timeout=TIMEOUT_SECONDS
        )
        
        end_time = time.time()
        duration = end_time - start_time
        
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                analysis = data.get('data', {}).get('analysis', {})
                print(f"✅ AI Analysis test: PASSED ({duration:.2f}s)")
                print(f"   Generated analysis types: {list(analysis.keys())}")
                
                # Check if analysis contains meaningful content
                meaningful_analysis = sum(1 for v in analysis.values() if v and len(v) > 50)
                print(f"   Meaningful analysis sections: {meaningful_analysis}/{len(analysis)}")
                
                return True
            else:
                print(f"❌ AI Analysis test: FAILED (API returned success=false)")
                print(f"   Message: {data.get('message', 'No message')}")
                return False
        else:
            print(f"❌ AI Analysis test: FAILED (Status: {response.status_code})")
            print(f"   Response: {response.text[:200]}...")
            return False
            
    except requests.exceptions.Timeout:
        print(f"❌ AI Analysis test: TIMEOUT after {TIMEOUT_SECONDS} seconds")
        return False
    except Exception as e:
        print(f"❌ AI Analysis test: FAILED (Error: {e})")
        return False

def test_ollama_connection():
    """Test direct Ollama connection"""
    try:
        response = requests.get("http://localhost:11434/api/tags", timeout=10)
        if response.status_code == 200:
            models = response.json().get('models', [])
            print(f"✅ Ollama connection: PASSED")
            print(f"   Available models: {[m.get('name') for m in models]}")
            return True
        else:
            print(f"❌ Ollama connection: FAILED (Status: {response.status_code})")
            return False
    except Exception as e:
        print(f"❌ Ollama connection: FAILED (Error: {e})")
        return False

def main():
    print("=" * 60)
    print("CRYPTO INSIGHT - TIMEOUT FIX VERIFICATION TEST")
    print("=" * 60)
    print(f"Test started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Maximum timeout for AI analysis: {TIMEOUT_SECONDS} seconds")
    print()
    
    tests_passed = 0
    total_tests = 4
    
    # Run tests
    if test_ollama_connection():
        tests_passed += 1
        
    if test_health_check():
        tests_passed += 1
        
    if test_market_data():
        tests_passed += 1
        
    if test_crypto_analysis():
        tests_passed += 1
    
    # Summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)
    print(f"Tests passed: {tests_passed}/{total_tests}")
    
    if tests_passed == total_tests:
        print("🎉 ALL TESTS PASSED! The timeout fixes appear to be working.")
    elif tests_passed >= 3:
        print("⚠️  Most tests passed. Some minor issues may remain.")
    else:
        print("❌ Several tests failed. Please check the troubleshooting guide.")
    
    print(f"\nTest completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    main()
