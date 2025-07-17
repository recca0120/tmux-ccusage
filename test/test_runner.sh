#!/usr/bin/env bash

# Simple test runner for tmux-ccusage

# Don't use strict mode in tests as it may cause issues with test assertions
set +e

cd "$(dirname "$0")/.."

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Disable colors only if NO_COLOR is set or not a terminal
# GitHub Actions supports ANSI colors
if [ -n "${NO_COLOR:-}" ] || ([ ! -t 1 ] && [ -z "${GITHUB_ACTIONS:-}" ]); then
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

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
        echo -e "${GREEN}✓${NC} $message"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}✗${NC} $message"
        echo -e "  ${YELLOW}Expected:${NC} '$expected'"
        echo -e "  ${YELLOW}Actual:${NC}   '$actual'"
    fi
}

# Run first test - JSON parser doesn't exist yet
echo -e "\n${BOLD}${BLUE}=== Testing JSON Parser ===${NC}"
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
echo -e "\n${BOLD}${BLUE}=== Testing Cache ===${NC}"
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
echo -e "\n${BOLD}${BLUE}=== Testing Formatter ===${NC}"
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
echo -e "\n${BOLD}${BLUE}=== Testing Integration ===${NC}"
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
echo -e "\n${BOLD}${BLUE}=== Test Summary ===${NC}"
echo -e "${BOLD}Tests run:${NC} $TESTS_RUN"
echo -e "${GREEN}${BOLD}Passed:${NC} $TESTS_PASSED"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}${BOLD}Failed:${NC} $TESTS_FAILED"
else
    echo -e "${BOLD}Failed:${NC} $TESTS_FAILED"
fi

# Final status
echo ""
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ All tests passed!${NC}"
else
    echo -e "${RED}${BOLD}✗ $TESTS_FAILED test(s) failed!${NC}"
fi

exit $TESTS_FAILED