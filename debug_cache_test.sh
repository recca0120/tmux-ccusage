#!/usr/bin/env bash

PROJECT_DIR="$(pwd)"
test_cache_dir="$PROJECT_DIR/test/tmp/debug_cache_integration"
mkdir -p "$test_cache_dir"

echo "=== Debug Cache Integration Test ==="
echo "PROJECT_DIR = $PROJECT_DIR"
echo "test_cache_dir = $test_cache_dir"

# Clear cache first
rm -f "$test_cache_dir/ccusage.json"

echo ""
echo "1. Testing env var visibility in function:"
test_in_function() {
    echo "In function - CCUSAGE_CACHE_DIR: $CCUSAGE_CACHE_DIR"
    local result=$(TMUX_TEST_MODE=1 CCUSAGE_CACHE_DIR="$test_cache_dir" "$PROJECT_DIR/tmux-ccusage.sh" 2>&1)
    echo "Function result: '$result'"
}

CCUSAGE_CACHE_DIR="$test_cache_dir"
test_in_function

echo ""
echo "2. Testing direct execution:"
result=$(TMUX_TEST_MODE=1 CCUSAGE_CACHE_DIR="$test_cache_dir" "$PROJECT_DIR/tmux-ccusage.sh" 2>&1)
echo "Direct result: '$result'"

echo ""
echo "3. Cache file status:"
echo "Cache file exists: $([ -f "$test_cache_dir/ccusage.json" ] && echo 'yes' || echo 'no')"
ls -la "$test_cache_dir/" 2>/dev/null || echo "Directory doesn't exist"