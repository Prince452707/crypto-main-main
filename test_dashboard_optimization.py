#!/usr/bin/env python3
"""
Test script to verify dashboard API call optimizations.
This script simulates dashboard usage patterns and monitors API call reduction.
"""

import requests
import time
import json
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading

BASE_URL = "http://localhost:8081/api/v1"
OPTIMIZED_URL = "http://localhost:8081/api/v1/optimized"

class APICallMonitor:
    def __init__(self):
        self.call_count = 0
        self.start_time = time.time()
        self.lock = threading.Lock()
        
    def record_call(self):
        with self.lock:
            self.call_count += 1
    
    def get_rate(self):
        elapsed = time.time() - self.start_time
        return self.call_count / elapsed if elapsed > 0 else 0

monitor = APICallMonitor()

def make_request(url, description):
    """Make an API request and record it"""
    monitor.record_call()
    try:
        start_time = time.time()
        response = requests.get(url, timeout=10)
        duration = time.time() - start_time
        
        if response.status_code == 200:
            print(f"✅ {description}: SUCCESS ({duration:.2f}s)")
            return True, duration
        else:
            print(f"❌ {description}: FAILED (Status: {response.status_code})")
            return False, duration
    except Exception as e:
        duration = time.time() - start_time
        print(f"❌ {description}: ERROR ({e}) ({duration:.2f}s)")
        return False, duration

def test_original_endpoints():
    """Test original endpoints to establish baseline"""
    print("\n🔍 Testing Original Endpoints (Baseline)")
    print("=" * 50)
    
    symbols = ["bitcoin", "ethereum", "cardano", "solana", "dogecoin"]
    success_count = 0
    total_time = 0
    
    for symbol in symbols:
        success, duration = make_request(f"{BASE_URL}/crypto/{symbol}", f"Original: {symbol}")
        if success:
            success_count += 1
        total_time += duration
        time.sleep(0.1)  # Small delay to avoid overwhelming
    
    print(f"\n📊 Original Endpoints Results:")
    print(f"   Success Rate: {success_count}/{len(symbols)} ({success_count/len(symbols)*100:.1f}%)")
    print(f"   Total Time: {total_time:.2f}s")
    print(f"   Average Time: {total_time/len(symbols):.2f}s per request")
    
    return success_count, total_time

def test_optimized_endpoints():
    """Test optimized endpoints"""
    print("\n🚀 Testing Optimized Endpoints")
    print("=" * 50)
    
    symbols = ["bitcoin", "ethereum", "cardano", "solana", "dogecoin"]
    success_count = 0
    total_time = 0
    
    # Test individual optimized requests
    for symbol in symbols:
        success, duration = make_request(f"{OPTIMIZED_URL}/crypto/{symbol}", f"Optimized: {symbol}")
        if success:
            success_count += 1
        total_time += duration
        time.sleep(0.1)
    
    # Test batch request
    print(f"\n🎯 Testing Batch Request...")
    batch_start = time.time()
    try:
        response = requests.post(f"{OPTIMIZED_URL}/crypto/batch", 
                               json=symbols, 
                               headers={'Content-Type': 'application/json'},
                               timeout=15)
        batch_duration = time.time() - batch_start
        monitor.record_call()
        
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                batch_count = len(data.get('data', []))
                print(f"✅ Batch request: SUCCESS - {batch_count} symbols in {batch_duration:.2f}s")
                success_count += 1
                total_time += batch_duration
            else:
                print(f"❌ Batch request: FAILED - {data.get('message', 'Unknown error')}")
        else:
            print(f"❌ Batch request: FAILED (Status: {response.status_code})")
    except Exception as e:
        batch_duration = time.time() - batch_start
        print(f"❌ Batch request: ERROR ({e})")
        total_time += batch_duration
    
    print(f"\n📊 Optimized Endpoints Results:")
    print(f"   Success Rate: {success_count}/{len(symbols)+1} ({success_count/(len(symbols)+1)*100:.1f}%)")
    print(f"   Total Time: {total_time:.2f}s")
    print(f"   Average Time: {total_time/(len(symbols)+1):.2f}s per request")
    
    return success_count, total_time

def test_cache_effectiveness():
    """Test cache effectiveness by making repeated requests"""
    print("\n💾 Testing Cache Effectiveness")
    print("=" * 50)
    
    symbol = "bitcoin"
    iterations = 5
    
    print(f"Making {iterations} requests for {symbol} to test caching...")
    
    times = []
    for i in range(iterations):
        start_time = time.time()
        success, duration = make_request(f"{OPTIMIZED_URL}/crypto/{symbol}", 
                                       f"Cache test {i+1}")
        times.append(duration)
        time.sleep(0.5)  # Small delay between requests
    
    if len(times) > 1:
        first_request = times[0]
        cached_requests = times[1:]
        avg_cached = sum(cached_requests) / len(cached_requests)
        
        print(f"\n📊 Cache Performance:")
        print(f"   First request: {first_request:.2f}s (fresh data)")
        print(f"   Cached requests: {avg_cached:.2f}s average")
        print(f"   Speed improvement: {(first_request - avg_cached) / first_request * 100:.1f}%")

def test_concurrent_requests():
    """Test system under concurrent load"""
    print("\n⚡ Testing Concurrent Load")
    print("=" * 50)
    
    symbols = ["bitcoin", "ethereum", "cardano", "solana", "dogecoin"] * 3  # 15 requests
    start_time = time.time()
    
    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = []
        for symbol in symbols:
            future = executor.submit(make_request, f"{OPTIMIZED_URL}/crypto/{symbol}", 
                                   f"Concurrent: {symbol}")
            futures.append(future)
        
        success_count = 0
        for future in as_completed(futures):
            success, _ = future.result()
            if success:
                success_count += 1
    
    total_time = time.time() - start_time
    
    print(f"\n📊 Concurrent Load Results:")
    print(f"   Requests: {len(symbols)}")
    print(f"   Success Rate: {success_count}/{len(symbols)} ({success_count/len(symbols)*100:.1f}%)")
    print(f"   Total Time: {total_time:.2f}s")
    print(f"   Requests per second: {len(symbols)/total_time:.1f}")

def test_cache_statistics():
    """Test cache statistics endpoint"""
    print("\n📈 Testing Cache Statistics")
    print("=" * 50)
    
    try:
        response = requests.get(f"{OPTIMIZED_URL}/cache/stats", timeout=10)
        monitor.record_call()
        
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                stats = data.get('data', {})
                print("✅ Cache Statistics:")
                for key, value in stats.items():
                    print(f"   {key}: {value}")
            else:
                print(f"❌ Cache stats: {data.get('message', 'Unknown error')}")
        else:
            print(f"❌ Cache stats: HTTP {response.status_code}")
    except Exception as e:
        print(f"❌ Cache stats: ERROR ({e})")

def test_rate_limiting():
    """Test rate limiting behavior"""
    print("\n🚧 Testing Rate Limiting")
    print("=" * 50)
    
    print("Making rapid requests to test rate limiting...")
    
    success_count = 0
    rate_limited_count = 0
    
    for i in range(25):  # Try to exceed rate limit
        try:
            response = requests.get(f"{BASE_URL}/crypto/bitcoin", timeout=5)
            monitor.record_call()
            
            if response.status_code == 200:
                success_count += 1
            elif response.status_code == 429:
                rate_limited_count += 1
                print(f"⚠️ Rate limited on request {i+1}")
            
        except Exception as e:
            print(f"❌ Request {i+1}: ERROR ({e})")
        
        time.sleep(0.1)  # Very short delay
    
    print(f"\n📊 Rate Limiting Results:")
    print(f"   Successful: {success_count}")
    print(f"   Rate limited: {rate_limited_count}")
    print(f"   Total requests: {success_count + rate_limited_count}")

def main():
    print("🔧 Dashboard API Call Optimization Test")
    print("=" * 60)
    print(f"⏰ Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"🌐 Base URL: {BASE_URL}")
    print(f"🚀 Optimized URL: {OPTIMIZED_URL}")
    
    # Test sequence
    try:
        # Baseline performance
        original_success, original_time = test_original_endpoints()
        
        # Optimized performance
        optimized_success, optimized_time = test_optimized_endpoints()
        
        # Cache effectiveness
        test_cache_effectiveness()
        
        # Concurrent load
        test_concurrent_requests()
        
        # Cache statistics
        test_cache_statistics()
        
        # Rate limiting
        test_rate_limiting()
        
        # Summary
        print("\n" + "=" * 60)
        print("📊 OPTIMIZATION SUMMARY")
        print("=" * 60)
        
        if original_time > 0:
            time_improvement = (original_time - optimized_time) / original_time * 100
            print(f"⏱️  Time Improvement: {time_improvement:.1f}%")
        
        print(f"📞 Total API Calls Made: {monitor.call_count}")
        print(f"📈 Average Call Rate: {monitor.get_rate():.1f} calls/second")
        
        # Performance recommendations
        print(f"\n💡 RECOMMENDATIONS:")
        if monitor.get_rate() > 10:
            print("   ⚠️ High API call rate detected - consider increasing cache TTL")
        else:
            print("   ✅ API call rate is within optimal range")
            
        if optimized_time < original_time:
            print("   ✅ Optimizations are effective")
        else:
            print("   ⚠️ Optimizations need review")
            
    except KeyboardInterrupt:
        print("\n🛑 Test interrupted by user")
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
    finally:
        print(f"\n⏰ Completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    main()
