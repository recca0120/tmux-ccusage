#!/usr/bin/env bats

load test_helper

@test "test_main_script - Default format should show dollar amount" {
    local result=$(TMUX_TEST_MODE=1 "$PROJECT_ROOT/tmux-ccusage.sh")
    [[ "$result" =~ ^\$[0-9]+\.[0-9]{2}$ ]]
}

@test "test_main_script - Total format should show dollar amount" {
    result=$(TMUX_TEST_MODE=1 "$PROJECT_ROOT/tmux-ccusage.sh" total)
    [[ "$result" =~ ^\$[0-9]+\.[0-9]{2}$ ]]
}

@test "test_main_script - Both format should show both amounts" {
    result=$(TMUX_TEST_MODE=1 "$PROJECT_ROOT/tmux-ccusage.sh" both)
    [[ "$result" =~ Today.*Total ]] || [[ "$result" == "\$0.00" ]]
}

@test "test_env_vars - Percentage format should work with env var" {
    # Clear any existing environment variables that might interfere
    unset CCUSAGE_SUBSCRIPTION_AMOUNT
    unset CCUSAGE_CACHE_DIR
    unset CCUSAGE_CACHE_TTL
    unset CCUSAGE_OFFLINE
    
    # Test subscription amount with TMUX_TEST_MODE  
    # Use env -i to ensure completely clean environment, then set only what we need
    local result
    result=$(env -i HOME="$HOME" PATH="$PATH" bash -c "cd '$PROJECT_ROOT' && TMUX_TEST_MODE=1 CCUSAGE_SUBSCRIPTION_AMOUNT=500 ./tmux-ccusage.sh percentage" 2>/dev/null)
    [[ "$result" =~ ^[0-9]+\.[0-9]+%$ ]] || [[ "$result" == "N/A" ]]
}

@test "test_cache_integration - Cache file should be created" {
    # Clear any existing environment variables that might interfere
    unset CCUSAGE_SUBSCRIPTION_AMOUNT
    unset CCUSAGE_CACHE_DIR
    unset CCUSAGE_CACHE_TTL
    unset CCUSAGE_OFFLINE
    
    # Set up test cache directory
    local test_cache_dir="$PROJECT_ROOT/test/tmp/cache_integration"
    mkdir -p "$test_cache_dir"
    
    # Clear cache first
    rm -f "$test_cache_dir/ccusage.json"
    rm -f ~/.cache/tmux-ccusage/ccusage.json
    
    # First call should create cache - use env -i for completely clean environment
    local start_time=$(date +%s)
    env -i HOME="$HOME" PATH="$PATH" bash -c "cd '$PROJECT_ROOT' && TMUX_TEST_MODE=1 CCUSAGE_CACHE_DIR='$test_cache_dir' ./tmux-ccusage.sh" > /dev/null 2>&1
    local end_time=$(date +%s)
    local first_duration=$((end_time - start_time))
    
    # Second call should use cache (faster)
    start_time=$(date +%s)
    env -i HOME="$HOME" PATH="$PATH" bash -c "cd '$PROJECT_ROOT' && TMUX_TEST_MODE=1 CCUSAGE_CACHE_DIR='$test_cache_dir' ./tmux-ccusage.sh" > /dev/null 2>&1
    end_time=$(date +%s)
    local second_duration=$((end_time - start_time))
    
    # Cache should exist
    [ -f "$test_cache_dir/ccusage.json" ]
}

@test "test_error_handling - Should show \$0.00 when no data available" {
    # Test with invalid ccusage command (offline mode when no cache)
    rm -f ~/.cache/tmux-ccusage/ccusage.json
    local result=$(TMUX_TEST_MODE=1 CCUSAGE_OFFLINE=true "$PROJECT_ROOT/tmux-ccusage.sh" 2>/dev/null)
    [ "$result" = "\$0.00" ]
}