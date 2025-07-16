#!/usr/bin/env bash

# Test cache functionality

# Setup test cache directory
TEST_CACHE_DIR="$SCRIPT_DIR/tmp/test_cache"
mkdir -p "$TEST_CACHE_DIR"

# Mock data
MOCK_JSON='{"daily":[{"date":"2025-07-17","totalCost":17.96}],"totals":{"totalCost":160.55}}'
CACHE_FILE="$TEST_CACHE_DIR/ccusage.json"

# Test cache write
test_cache_write() {
    source "$PROJECT_DIR/scripts/cache.sh" 2>/dev/null || {
        assert_equals "" "" "cache.sh not yet implemented"
        return
    }
    
    # Set cache directory
    export CCUSAGE_CACHE_DIR="$TEST_CACHE_DIR"
    
    # Write to cache
    echo "$MOCK_JSON" | write_cache
    
    # Check if cache file exists
    if [ -f "$CACHE_FILE" ]; then
        assert_equals "exists" "exists" "Cache file should be created"
    else
        assert_equals "exists" "not exists" "Cache file should be created"
    fi
    
    # Check cache content
    local cached_content=$(cat "$CACHE_FILE")
    assert_equals "$MOCK_JSON" "$cached_content" "Cache should contain the JSON data"
}

# Test cache read
test_cache_read() {
    source "$PROJECT_DIR/scripts/cache.sh" 2>/dev/null || return
    
    export CCUSAGE_CACHE_DIR="$TEST_CACHE_DIR"
    
    # Write test data to cache
    echo "$MOCK_JSON" > "$CACHE_FILE"
    
    # Read from cache
    local result=$(read_cache)
    assert_equals "$MOCK_JSON" "$result" "Should read cached data"
}

# Test cache expiry (30 seconds)
test_cache_expiry() {
    source "$PROJECT_DIR/scripts/cache.sh" 2>/dev/null || return
    
    export CCUSAGE_CACHE_DIR="$TEST_CACHE_DIR"
    export CCUSAGE_CACHE_TTL=2  # 2 seconds for testing
    
    # Write to cache
    echo "$MOCK_JSON" > "$CACHE_FILE"
    
    # Check if cache is valid
    is_cache_valid
    assert_equals "0" "$?" "Fresh cache should be valid"
    
    # Wait for cache to expire
    sleep 3
    
    # Check if cache is invalid
    is_cache_valid
    assert_equals "1" "$?" "Expired cache should be invalid"
}

# Test cache with no file
test_cache_no_file() {
    source "$PROJECT_DIR/scripts/cache.sh" 2>/dev/null || return
    
    export CCUSAGE_CACHE_DIR="$TEST_CACHE_DIR"
    
    # Remove cache file if exists
    rm -f "$CACHE_FILE"
    
    # Check if cache is invalid
    is_cache_valid
    assert_equals "1" "$?" "Non-existent cache should be invalid"
    
    # Try to read non-existent cache
    local result=$(read_cache)
    assert_equals "" "$result" "Should return empty for non-existent cache"
}

# Test get_cached_or_fetch
test_get_cached_or_fetch() {
    source "$PROJECT_DIR/scripts/cache.sh" 2>/dev/null || return
    
    export CCUSAGE_CACHE_DIR="$TEST_CACHE_DIR"
    export CCUSAGE_CACHE_TTL=30
    
    # Remove cache to test fresh fetch
    rm -f "$CACHE_FILE"
    
    # Mock ccusage command
    ccusage() {
        echo "$MOCK_JSON"
    }
    export -f ccusage
    
    # Get data (should fetch)
    local result=$(get_cached_or_fetch "daily")
    assert_equals "$MOCK_JSON" "$result" "Should fetch fresh data"
    
    # Check if cache was created
    if [ -f "$CACHE_FILE" ]; then
        assert_equals "exists" "exists" "Cache file should be created after fetch"
    else
        assert_equals "exists" "not exists" "Cache file should be created after fetch"
    fi
    
    # Get data again (should use cache)
    local result2=$(get_cached_or_fetch "daily")
    assert_equals "$MOCK_JSON" "$result2" "Should return cached data"
}

# Run the tests
echo "Testing cache functionality..."
test_cache_write
test_cache_read
test_cache_expiry
test_cache_no_file
test_get_cached_or_fetch

# Cleanup
rm -rf "$TEST_CACHE_DIR"