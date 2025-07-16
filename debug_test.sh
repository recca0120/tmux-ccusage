#!/usr/bin/env bash

PROJECT_DIR="$(pwd)"
echo "PROJECT_DIR = $PROJECT_DIR"

echo "Testing percentage..."
result=$(TMUX_TEST_MODE=1 CCUSAGE_SUBSCRIPTION_AMOUNT=500 "$PROJECT_DIR/tmux-ccusage.sh" percentage 2>&1)
echo "Result: '$result'"

echo ""
echo "Testing cache..."
test_cache_dir="$PROJECT_DIR/test/tmp/debug_cache"
mkdir -p "$test_cache_dir"
rm -f "$test_cache_dir/ccusage.json"

result=$(TMUX_TEST_MODE=1 CCUSAGE_CACHE_DIR="$test_cache_dir" "$PROJECT_DIR/tmux-ccusage.sh" 2>&1)
echo "Script result: '$result'"
echo "Cache file exists: $([ -f "$test_cache_dir/ccusage.json" ] && echo 'yes' || echo 'no')"
ls -la "$test_cache_dir/" || echo "Directory doesn't exist"