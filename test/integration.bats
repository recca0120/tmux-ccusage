#!/usr/bin/env bats

load test_helper

@test "tmux-ccusage.sh with default format" {
    result=$("$PROJECT_ROOT/tmux-ccusage.sh")
    [[ "$result" =~ ^\$[0-9]+\.[0-9]{2}$ ]]
}

@test "tmux-ccusage.sh with total format" {
    result=$("$PROJECT_ROOT/tmux-ccusage.sh" total)
    [[ "$result" =~ ^\$[0-9]+\.[0-9]{2}$ ]]
}

@test "tmux-ccusage.sh with both format" {
    result=$("$PROJECT_ROOT/tmux-ccusage.sh" both)
    [[ "$result" =~ Today.*Total ]] || [ "$result" = "\$0.00" ]
}

@test "tmux-ccusage.sh with percentage format and env var" {
    export CCUSAGE_SUBSCRIPTION_AMOUNT=500
    result=$("$PROJECT_ROOT/tmux-ccusage.sh" percentage)
    [[ "$result" =~ ^[0-9]+\.[0-9]+%$ ]] || [ "$result" = "N/A" ]
    unset CCUSAGE_SUBSCRIPTION_AMOUNT
}

@test "tmux-ccusage.sh with remaining format" {
    export CCUSAGE_SUBSCRIPTION_AMOUNT=200
    result=$("$PROJECT_ROOT/tmux-ccusage.sh" remaining)
    [[ "$result" =~ ^\$[0-9]+\.[0-9]+/\$[0-9]+ ]]
    unset CCUSAGE_SUBSCRIPTION_AMOUNT
}

@test "tmux-ccusage.sh with status format" {
    export CCUSAGE_SUBSCRIPTION_AMOUNT=200
    result=$("$PROJECT_ROOT/tmux-ccusage.sh" status)
    [[ "$result" =~ \$[0-9]+\.[0-9]+ ]]
    unset CCUSAGE_SUBSCRIPTION_AMOUNT
}

@test "tmux-ccusage.sh with monthly format" {
    result=$("$PROJECT_ROOT/tmux-ccusage.sh" monthly)
    [[ "$result" =~ ^\$[0-9]+\.[0-9]{2}$ ]]
}

@test "tmux-ccusage.sh with custom format" {
    export CCUSAGE_CUSTOM_FORMAT='Cost: #{today}'
    result=$("$PROJECT_ROOT/tmux-ccusage.sh" custom)
    [[ "$result" =~ ^Cost:.*\$[0-9]+\.[0-9]{2}$ ]]
    unset CCUSAGE_CUSTOM_FORMAT
}

@test "tmux-ccusage.sh handles errors gracefully" {
    # Test with offline mode which should return $0.00 if no cache
    clear_cache
    export CCUSAGE_OFFLINE=true
    
    result=$("$PROJECT_ROOT/tmux-ccusage.sh")
    [ "$result" = "\$0.00" ]
    
    unset CCUSAGE_OFFLINE
}

@test "tmux-ccusage.sh respects cache TTL" {
    export CCUSAGE_CACHE_TTL=1
    
    # First call should create cache
    result1=$("$PROJECT_ROOT/tmux-ccusage.sh")
    [ -f "$CCUSAGE_CACHE_DIR/ccusage.json" ]
    
    # Second call should use cache
    result2=$("$PROJECT_ROOT/tmux-ccusage.sh")
    [ "$result1" = "$result2" ]
    
    # Wait for cache to expire
    sleep 2
    
    # Third call should fetch fresh data
    result3=$("$PROJECT_ROOT/tmux-ccusage.sh")
    [ "$result3" = "$result1" ]  # Should be same since mock data is static
    
    unset CCUSAGE_CACHE_TTL
}