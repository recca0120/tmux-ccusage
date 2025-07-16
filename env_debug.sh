#!/usr/bin/env bash

echo "=== Environment Variable Debug ==="

PROJECT_DIR="$(pwd)"
test_cache_dir="$PROJECT_DIR/test/tmp/env_debug"
mkdir -p "$test_cache_dir"

echo "1. Testing env var in current shell:"
TMUX_TEST_MODE=1 CCUSAGE_SUBSCRIPTION_AMOUNT=500 bash -c 'echo "TMUX_TEST_MODE=$TMUX_TEST_MODE, CCUSAGE_SUBSCRIPTION_AMOUNT=$CCUSAGE_SUBSCRIPTION_AMOUNT"'

echo ""
echo "2. Testing env var with $(command) subshell:"
result=$(TMUX_TEST_MODE=1 CCUSAGE_SUBSCRIPTION_AMOUNT=500 bash -c 'echo "TMUX_TEST_MODE=$TMUX_TEST_MODE, CCUSAGE_SUBSCRIPTION_AMOUNT=$CCUSAGE_SUBSCRIPTION_AMOUNT"')
echo "Result: $result"

echo ""
echo "3. Testing in function like integration test:"
test_in_function() {
    local result=$(TMUX_TEST_MODE=1 CCUSAGE_SUBSCRIPTION_AMOUNT=500 bash -c 'echo "TMUX_TEST_MODE=$TMUX_TEST_MODE, CCUSAGE_SUBSCRIPTION_AMOUNT=$CCUSAGE_SUBSCRIPTION_AMOUNT"')
    echo "Function result: $result"
}
test_in_function

echo ""
echo "4. Testing actual script execution:"
result=$(TMUX_TEST_MODE=1 CCUSAGE_SUBSCRIPTION_AMOUNT=500 bash -c 'echo "In script: TMUX_TEST_MODE=$TMUX_TEST_MODE, CCUSAGE_SUBSCRIPTION_AMOUNT=$CCUSAGE_SUBSCRIPTION_AMOUNT"; '"$PROJECT_DIR/tmux-ccusage.sh"' percentage')
echo "Script result: $result"