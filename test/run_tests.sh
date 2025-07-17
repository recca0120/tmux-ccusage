#!/usr/bin/env bash

# Test runner for tmux-ccusage

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test framework functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$expected" = "$actual" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} $message"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}✗${NC} $message"
        echo -e "  Expected: '$expected'"
        echo -e "  Actual:   '$actual'"
    fi
}

assert_true() {
    local condition="$1"
    local message="${2:-}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if eval "$condition"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} $message"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}✗${NC} $message"
        echo -e "  Condition failed: $condition"
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist: $file}"
    
    assert_true "[ -f '$file' ]" "$message"
}

assert_file_contains() {
    local file="$1"
    local content="$2"
    local message="${3:-File should contain: $content}"
    
    assert_true "grep -q '$content' '$file'" "$message"
}

# Setup test environment
setup() {
    export TEST_MODE=1
    export CCUSAGE_CACHE_DIR="$SCRIPT_DIR/tmp/cache"
    mkdir -p "$CCUSAGE_CACHE_DIR"
}

# Cleanup test environment
teardown() {
    rm -rf "$SCRIPT_DIR/tmp"
}

# Run all test files
echo -e "${YELLOW}Running tmux-ccusage tests...${NC}"

setup

# Source the test files
for test_file in "$SCRIPT_DIR"/test_*.sh; do
    if [ -f "$test_file" ] && [ "$test_file" != "$SCRIPT_DIR/run_tests.sh" ]; then
        echo -e "${YELLOW}Running $(basename "$test_file")...${NC}"
        source "$test_file"
    fi
done

teardown

# Summary
echo -e "${YELLOW}Test Summary:${NC}"
echo -e "Tests run: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed!${NC}"
    exit 1
fi