#!/usr/bin/env bats

load test_helper

setup() {
    # Setup test cache directory
    export TEST_CACHE_DIR="$BATS_TEST_TMPDIR/test_cache"
    mkdir -p "$TEST_CACHE_DIR"
    export CCUSAGE_CACHE_DIR="$TEST_CACHE_DIR"
}

teardown() {
    # Cleanup
    rm -rf "$TEST_CACHE_DIR"
    unset CCUSAGE_CACHE_DIR
    unset CCUSAGE_CACHE_TTL
}

@test "test_cache_write - Cache file should be created" {
    # Write to cache
    echo "$MOCK_JSON" | write_cache
    
    # Check if cache file exists
    local cache_file
    cache_file=$(get_cache_file)
    [ -f "$cache_file" ]
}

@test "test_cache_write - Cache should contain the JSON data" {
    # Write to cache
    echo "$MOCK_JSON" | write_cache
    
    # Check cache content
    local cache_file
    cache_file=$(get_cache_file)
    local cached_content=$(cat "$cache_file")
    [ "$cached_content" = "$MOCK_JSON" ]
}

@test "test_cache_read - Should read cached data" {
    # Write test data to cache
    local cache_file
    cache_file=$(get_cache_file)
    echo "$MOCK_JSON" > "$cache_file"
    
    # Read from cache
    local result=$(read_cache)
    [ "$result" = "$MOCK_JSON" ]
}

@test "test_cache_expiry - Fresh cache should be valid" {
    export CCUSAGE_CACHE_TTL=1  # 1 second for testing
    
    # Write to cache
    local cache_file
    cache_file=$(get_cache_file)
    echo "$MOCK_JSON" > "$cache_file"
    
    # Check if cache is valid
    is_cache_valid
}

@test "test_cache_expiry - Expired cache should be invalid" {
    export CCUSAGE_CACHE_TTL=1  # 1 second for testing
    
    # Write to cache
    local cache_file
    cache_file=$(get_cache_file)
    echo "$MOCK_JSON" > "$cache_file"
    
    # Manually modify file timestamp to simulate expiry
    touch -t 202001010000 "$cache_file"
    
    # Check if cache is invalid
    ! is_cache_valid
}

@test "test_cache_no_file - Non-existent cache should be invalid" {
    # Remove cache file if exists
    local cache_file
    cache_file=$(get_cache_file)
    rm -f "$cache_file"
    
    # Check if cache is invalid
    ! is_cache_valid
}

@test "test_cache_no_file - Should return empty for non-existent cache" {
    # Remove cache file if exists
    local cache_file
    cache_file=$(get_cache_file)
    rm -f "$cache_file"
    
    # Try to read non-existent cache
    local result=$(read_cache)
    [ -z "$result" ]
}

@test "test_get_cached_or_fetch - Should fetch fresh data" {
    export CCUSAGE_CACHE_TTL=30
    
    # Remove cache to test fresh fetch
    local cache_file
    cache_file=$(get_cache_file)
    rm -f "$cache_file"
    
    # Get data (should fetch)
    local result=$(get_cached_or_fetch "daily")
    
    # The mock ccusage now returns multi-day data
    local expected_json='{
                  "daily": [
                    {"date": "2025-07-14", "totalCost": 8.94},
                    {"date": "2025-07-15", "totalCost": 3.20},
                    {"date": "2025-07-16", "totalCost": 130.45},
                    {"date": "2025-07-17", "totalCost": 17.96}
                  ],
                  "totals": {"totalCost": 160.55}
                }'
    [ "$result" = "$expected_json" ]
}

@test "test_get_cached_or_fetch - Cache file should be created after fetch" {
    export CCUSAGE_CACHE_TTL=30
    
    # Remove cache to test fresh fetch
    local cache_file
    cache_file=$(get_cache_file)
    rm -f "$cache_file"
    
    # Get data (should fetch)
    get_cached_or_fetch "daily" >/dev/null
    
    # Check if cache was created
    cache_file=$(get_cache_file)
    [ -f "$cache_file" ]
}

@test "test_get_cached_or_fetch - Should return cached data" {
    export CCUSAGE_CACHE_TTL=30
    
    # Remove cache to test fresh fetch
    local cache_file
    cache_file=$(get_cache_file)
    rm -f "$cache_file"
    
    # Get data (should fetch)
    get_cached_or_fetch "daily" >/dev/null
    
    # Get data again (should use cache)
    local result2=$(get_cached_or_fetch "daily")
    
    # The mock ccusage now returns multi-day data
    local expected_json='{
                  "daily": [
                    {"date": "2025-07-14", "totalCost": 8.94},
                    {"date": "2025-07-15", "totalCost": 3.20},
                    {"date": "2025-07-16", "totalCost": 130.45},
                    {"date": "2025-07-17", "totalCost": 17.96}
                  ],
                  "totals": {"totalCost": 160.55}
                }'
    [ "$result2" = "$expected_json" ]
}