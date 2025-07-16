#!/usr/bin/env bats

# Test cache functionality using Bats

setup() {
    # Load the script
    source "${BATS_TEST_DIRNAME}/../../scripts/cache.sh"
    
    # Setup test cache directory
    export TEST_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
    export CCUSAGE_CACHE_DIR="$TEST_CACHE_DIR"
    export CACHE_FILE="$TEST_CACHE_DIR/ccusage.json"
    
    mkdir -p "$TEST_CACHE_DIR"
    
    # Mock JSON
    export MOCK_JSON='{"daily":[{"date":"2025-07-17","totalCost":17.96}],"totals":{"totalCost":160.55}}'
}

teardown() {
    rm -rf "$TEST_CACHE_DIR"
}

@test "write_cache creates cache file" {
    echo "$MOCK_JSON" | write_cache
    [ -f "$CACHE_FILE" ]
}

@test "write_cache stores correct content" {
    echo "$MOCK_JSON" | write_cache
    cached_content=$(cat "$CACHE_FILE")
    [ "$cached_content" = "$MOCK_JSON" ]
}

@test "read_cache returns cached data" {
    echo "$MOCK_JSON" > "$CACHE_FILE"
    result=$(read_cache)
    [ "$result" = "$MOCK_JSON" ]
}

@test "is_cache_valid returns true for fresh cache" {
    echo "$MOCK_JSON" > "$CACHE_FILE"
    run is_cache_valid
    [ "$status" -eq 0 ]
}

@test "is_cache_valid returns false for expired cache" {
    export CCUSAGE_CACHE_TTL=1
    echo "$MOCK_JSON" > "$CACHE_FILE"
    sleep 2
    run is_cache_valid
    [ "$status" -eq 1 ]
}

@test "is_cache_valid returns false for non-existent cache" {
    rm -f "$CACHE_FILE"
    run is_cache_valid
    [ "$status" -eq 1 ]
}

@test "read_cache returns empty for non-existent file" {
    rm -f "$CACHE_FILE"
    result=$(read_cache)
    [ -z "$result" ]
}

@test "get_cached_or_fetch returns fresh data when no cache" {
    rm -f "$CACHE_FILE"
    
    # Mock ccusage command
    ccusage() {
        echo "$MOCK_JSON"
    }
    export -f ccusage
    
    result=$(get_cached_or_fetch "daily")
    [ "$result" = "$MOCK_JSON" ]
    [ -f "$CACHE_FILE" ]
}

@test "clear_cache removes cache file" {
    echo "$MOCK_JSON" > "$CACHE_FILE"
    clear_cache
    [ ! -f "$CACHE_FILE" ]
}