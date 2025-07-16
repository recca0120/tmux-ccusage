#!/usr/bin/env bash

# Simple test runner for tmux-ccusage

# Don't use strict mode in tests as it may cause issues with test assertions
set +e

cd "$(dirname "$0")/.."

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Enable debug mode if CI environment
if [ -n "${CI:-}" ]; then
    set -x
fi

# Test functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Test}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$expected" = "$actual" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "✓ $message"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "✗ $message"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
    fi
}

# Run first test - JSON parser doesn't exist yet
echo "=== Testing JSON Parser ==="
if [ ! -f "scripts/json_parser.sh" ]; then
    echo "✗ json_parser.sh not yet implemented (expected in TDD)"
    TESTS_RUN=1
    TESTS_FAILED=1
else
    source scripts/json_parser.sh
    
    # Test with mock data
    MOCK_JSON='{"daily":[{"date":"2025-07-17","totalCost":17.96}],"totals":{"totalCost":160.55}}'
    
    result=$(echo "$MOCK_JSON" | get_today_cost)
    assert_equals "17.96" "$result" "get_today_cost should return 17.96"
    
    result=$(echo "$MOCK_JSON" | get_total_cost)
    assert_equals "160.55" "$result" "get_total_cost should return 160.55"
    
    # Test empty JSON
    result=$(echo '{}' | get_today_cost)
    assert_equals "0.00" "$result" "empty JSON should return 0.00"
    
    # Test invalid JSON
    result=$(echo 'invalid' | get_today_cost)
    assert_equals "0.00" "$result" "invalid JSON should return 0.00"
    
    # Test get_cost_by_date
    result=$(echo "$MOCK_JSON" | get_cost_by_date "2025-07-17")
    assert_equals "17.96" "$result" "get_cost_by_date should return 17.96"
fi

# Test cache functionality
echo
echo "=== Testing Cache ==="
if [ ! -f "scripts/cache.sh" ]; then
    echo "✗ cache.sh not yet implemented (expected in TDD)"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
else
    # Run cache tests
    SCRIPT_DIR="$(pwd)/test"
    PROJECT_DIR="$(pwd)"
    source test/test_cache.sh
    
    # Clean up environment variables after cache tests
    unset CCUSAGE_CACHE_DIR
    unset CCUSAGE_CACHE_TTL
fi

# Test formatter functionality
echo
echo "=== Testing Formatter ==="
if [ ! -f "scripts/formatter.sh" ]; then
    echo "✗ formatter.sh not yet implemented (expected in TDD)"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
else
    # Run formatter tests
    source test/test_formatter.sh
    
    # Clean up environment variables after formatter tests
    unset CCUSAGE_SUBSCRIPTION_AMOUNT
    unset CCUSAGE_CUSTOM_FORMAT
    unset CCUSAGE_WARNING_THRESHOLD
    unset CCUSAGE_CRITICAL_THRESHOLD
fi

# Integration tests
echo
echo "=== Testing Integration ==="
if [ -f "tmux-ccusage.sh" ]; then
    PROJECT_DIR="$(pwd)"
    source test/test_integration.sh
else
    echo "✗ Main script not found"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Summary
echo
echo "=== Test Summary ==="
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

exit $TESTS_FAILED