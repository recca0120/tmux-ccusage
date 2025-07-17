#!/usr/bin/env bats

load test_helper

setup() {
    # Create test cache directory
    mkdir -p "$CCUSAGE_CACHE_DIR"
}

teardown() {
    # Clean up test cache
    rm -rf "$CCUSAGE_CACHE_DIR"
}

@test "write_cache creates cache file" {
    echo "$MOCK_JSON" | write_cache
    [ -f "$CCUSAGE_CACHE_DIR/ccusage.json" ]
}

@test "write_cache stores correct content" {
    echo "$MOCK_JSON" | write_cache
    cached_content=$(cat "$CCUSAGE_CACHE_DIR/ccusage.json")
    [ "$cached_content" = "$MOCK_JSON" ]
}

@test "read_cache returns cached data" {
    echo "$MOCK_JSON" > "$CCUSAGE_CACHE_DIR/ccusage.json"
    result=$(read_cache)
    [ "$result" = "$MOCK_JSON" ]
}

@test "is_cache_valid returns true for fresh cache" {
    export CCUSAGE_CACHE_TTL=30
    echo "$MOCK_JSON" > "$CCUSAGE_CACHE_DIR/ccusage.json"
    is_cache_valid
}

@test "is_cache_valid returns false for expired cache" {
    export CCUSAGE_CACHE_TTL=1
    echo "$MOCK_JSON" > "$CCUSAGE_CACHE_DIR/ccusage.json"
    touch -t 202001010000 "$CCUSAGE_CACHE_DIR/ccusage.json"
    ! is_cache_valid
}

@test "is_cache_valid returns false for non-existent cache" {
    ! is_cache_valid
}

@test "read_cache returns empty for non-existent file" {
    result=$(read_cache)
    [ -z "$result" ]
}

@test "get_cached_or_fetch returns fresh data when no cache" {
    result=$(get_cached_or_fetch daily)
    [ -n "$result" ]
    [ -f "$CCUSAGE_CACHE_DIR/ccusage.json" ]
}

@test "clear_cache removes cache file" {
    echo "$MOCK_JSON" > "$CCUSAGE_CACHE_DIR/ccusage.json"
    clear_cache
    [ ! -f "$CCUSAGE_CACHE_DIR/ccusage.json" ]
}

@test "get_cache_dir returns configured directory" {
    result=$(get_cache_dir)
    [ "$result" = "$CCUSAGE_CACHE_DIR" ]
}

@test "get_cache_ttl returns configured TTL" {
    export CCUSAGE_CACHE_TTL=60
    result=$(get_cache_ttl)
    [ "$result" = "60" ]
}

@test "get_cache_ttl returns default when not set" {
    unset CCUSAGE_CACHE_TTL
    result=$(get_cache_ttl)
    [ "$result" = "30" ]
}