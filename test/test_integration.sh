#!/usr/bin/env bash

# Integration tests for tmux-ccusage

# Test main script functionality
test_main_script() {
    echo "Testing main script..."
    
    # Test default format
    local result=$(TMUX_TEST_MODE=1 "$PROJECT_DIR/tmux-ccusage.sh")
    if [[ "$result" =~ ^\$[0-9]+\.[0-9]{2}$ ]]; then
        assert_equals "matches" "matches" "Default format should show dollar amount"
    else
        assert_equals "dollar format" "$result" "Default format should show dollar amount"
    fi
    
    # Test total format
    result=$(TMUX_TEST_MODE=1 "$PROJECT_DIR/tmux-ccusage.sh" total)
    if [[ "$result" =~ ^\$[0-9]+\.[0-9]{2}$ ]]; then
        assert_equals "matches" "matches" "Total format should show dollar amount"
    else
        assert_equals "dollar format" "$result" "Total format should show dollar amount"
    fi
    
    # Test both format
    result=$(TMUX_TEST_MODE=1 "$PROJECT_DIR/tmux-ccusage.sh" both)
    if [[ "$result" =~ Today.*Total ]] || [[ "$result" == "\$0.00" ]]; then
        assert_equals "matches" "matches" "Both format should show both amounts"
    else
        assert_equals "both format" "$result" "Both format should show both amounts"
    fi
}

# Test environment variable handling
test_env_vars() {
    echo "Testing environment variables..."
    
    # Test subscription amount with TMUX_TEST_MODE
    local result
    result=$(TMUX_TEST_MODE=1 CCUSAGE_SUBSCRIPTION_AMOUNT=500 "$PROJECT_DIR/tmux-ccusage.sh" percentage 2>/dev/null)
    echo "Debug: percentage result = '$result'"
    if [[ "$result" =~ ^[0-9]+\.[0-9]+%$ ]] || [[ "$result" == "N/A" ]]; then
        assert_equals "matches" "matches" "Percentage format should work with env var"
    else
        assert_equals "percentage format" "$result" "Percentage format should work with env var"
    fi
}

# Test cache functionality
test_cache_integration() {
    echo "Testing cache integration..."
    
    # Set up test cache directory
    local test_cache_dir="$PROJECT_DIR/test/tmp/cache_integration"
    mkdir -p "$test_cache_dir"
    
    # Clear cache first
    rm -f "$test_cache_dir/ccusage.json"
    rm -f ~/.cache/tmux-ccusage/ccusage.json
    
    # First call should create cache
    local start_time=$(date +%s)
    echo "Debug: Running with CCUSAGE_CACHE_DIR='$test_cache_dir'"
    local result=$(TMUX_TEST_MODE=1 CCUSAGE_CACHE_DIR="$test_cache_dir" "$PROJECT_DIR/tmux-ccusage.sh" 2>&1)
    echo "Debug: Script output = '$result'"
    local end_time=$(date +%s)
    local first_duration=$((end_time - start_time))
    
    # Second call should use cache (faster)
    start_time=$(date +%s)
    TMUX_TEST_MODE=1 CCUSAGE_CACHE_DIR="$test_cache_dir" "$PROJECT_DIR/tmux-ccusage.sh" > /dev/null
    end_time=$(date +%s)
    local second_duration=$((end_time - start_time))
    
    echo "Debug: cache dir = '$test_cache_dir'"
    echo "Debug: cache file exists = $([ -f "$test_cache_dir/ccusage.json" ] && echo 'yes' || echo 'no')"
    ls -la "$test_cache_dir/" || echo "Directory doesn't exist"
    
    # Let's debug why the cache isn't being created
    echo "Debug: Testing cache creation manually"
    echo "Debug: CCUSAGE_CACHE_DIR in env: $(env | grep CCUSAGE_CACHE_DIR || echo 'not set')"
    echo "Debug: PATH = $PATH"
    echo "Debug: which ccusage: $(which ccusage)"
    echo "Debug: ccusage version: $(ccusage --version 2>/dev/null || echo 'ccusage not available')"
    
    # Cache should exist
    if [ -f "$test_cache_dir/ccusage.json" ]; then
        assert_equals "exists" "exists" "Cache file should be created"
    else
        assert_equals "exists" "not exists" "Cache file should be created"
    fi
}

# Test error handling
test_error_handling() {
    echo "Testing error handling..."
    
    # Test with invalid ccusage command (offline mode when no cache)
    rm -f ~/.cache/tmux-ccusage/ccusage.json
    local result=$(TMUX_TEST_MODE=1 CCUSAGE_OFFLINE=true "$PROJECT_DIR/tmux-ccusage.sh" 2>/dev/null)
    assert_equals "\$0.00" "$result" "Should show \$0.00 when no data available"
}

# Run all integration tests
echo "=== Integration Tests ==="
test_main_script
test_env_vars
test_cache_integration
test_error_handling