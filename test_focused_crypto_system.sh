#!/bin/bash

# Test script for the Focused Crypto System
# This script tests the new API endpoints for comprehensive crypto data

BASE_URL="http://localhost:8081/api/v1/crypto/focused"

echo "=== Testing Focused Crypto System ==="
echo "Base URL: $BASE_URL"
echo ""

# Function to make API request and format response
test_endpoint() {
    local endpoint="$1"
    local description="$2"
    local method="${3:-GET}"
    
    echo "Testing: $description"
    echo "Endpoint: $method $endpoint"
    echo "Response:"
    
    if [ "$method" = "POST" ]; then
        curl -s -X POST "$endpoint" \
             -H "Content-Type: application/json" \
             | jq '.' 2>/dev/null || curl -s -X POST "$endpoint"
    elif [ "$method" = "DELETE" ]; then
        curl -s -X DELETE "$endpoint" \
             -H "Content-Type: application/json" \
             | jq '.' 2>/dev/null || curl -s -X DELETE "$endpoint"
    else
        curl -s "$endpoint" \
             -H "Content-Type: application/json" \
             | jq '.' 2>/dev/null || curl -s "$endpoint"
    fi
    
    echo ""
    echo "---"
    echo ""
}

# Test 1: Get focused data for AVAX (the crypto you mentioned)
test_endpoint "$BASE_URL/avalanche" "Get AVAX (Avalanche) comprehensive data"

# Test 2: Get focused data for Bitcoin
test_endpoint "$BASE_URL/bitcoin" "Get Bitcoin comprehensive data"

# Test 3: Force refresh AVAX data
test_endpoint "$BASE_URL/avalanche?forceRefresh=true" "Force refresh AVAX data"

# Test 4: Get rate limiting status
test_endpoint "$BASE_URL/status/rate-limits" "Get rate limiting status"

# Test 5: Refresh crypto data using POST endpoint
test_endpoint "$BASE_URL/bitcoin/refresh" "Refresh Bitcoin data" "POST"

# Test 6: Clear cache for a specific crypto
test_endpoint "$BASE_URL/bitcoin/cache" "Clear Bitcoin cache" "DELETE"

# Test 7: Preload popular cryptocurrencies
test_endpoint "$BASE_URL/preload" "Preload popular cryptocurrencies" "POST"

# Test 8: Test with different crypto IDs
echo "Testing various crypto identifiers:"
cryptos=("ethereum" "ETH" "binancecoin" "BNB" "solana" "SOL" "cardano" "ADA")

for crypto in "${cryptos[@]}"; do
    echo "Testing crypto: $crypto"
    curl -s "$BASE_URL/$crypto" -H "Content-Type: application/json" | jq '.success' 2>/dev/null || echo "Failed"
    echo ""
done

echo "=== Test Summary ==="
echo "1. Check that the backend is running on port 8081"
echo "2. Verify that the new endpoints are responding"
echo "3. Monitor the backend logs for rate limiting information"
echo "4. Check that data is being aggregated from multiple providers"
echo ""
echo "Expected benefits:"
echo "- Reduced 429 rate limiting errors"
echo "- More comprehensive crypto data"
echo "- Better error handling and fallbacks"
echo "- Intelligent caching and provider selection"
echo ""
echo "To monitor rate limits in real-time:"
echo "curl -s '$BASE_URL/status/rate-limits' | jq '.rateLimitStatus'"
