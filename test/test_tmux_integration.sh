#!/usr/bin/env bash

# Comprehensive tmux integration tests
# These tests require a real tmux installation and test actual tmux functionality

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test functions
assert_test() {
    local test_name="$1"
    local condition="$2"
    local message="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$condition" = "true" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "✓ $test_name: $message"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "✗ $test_name: $message"
        return 1
    fi
}

echo "=== tmux Integration Tests ==="
echo "Testing real tmux functionality with tmux-ccusage"
echo

# Check if tmux is available
if ! command -v tmux &> /dev/null; then
    echo "Error: tmux is not installed. These tests require tmux."
    exit 1
fi

# Ensure mock ccusage is available
if ! command -v ccusage &> /dev/null; then
    echo "Error: ccusage command not found. Make sure it's in PATH for testing."
    exit 1
fi

# Clean up any existing test sessions
tmux kill-session -t tmux-test-main 2>/dev/null || true
tmux kill-session -t tmux-test-options 2>/dev/null || true

# Start test sessions
echo "Starting tmux test sessions..."
tmux new-session -d -s tmux-test-main 'sleep 3600'
tmux new-session -d -s tmux-test-options 'sleep 3600'
sleep 1

echo "Active tmux sessions:"
tmux list-sessions

# Test 1: Basic tmux environment detection
echo
echo "Test 1: tmux environment detection"

# Get the actual tmux socket path
tmux_socket=$(tmux display-message -p "#{socket_path}")
export TMUX="$tmux_socket,1234,0"

result=$(./tmux-ccusage.sh)
echo "Result in tmux environment: $result"

if [[ "$result" =~ ^\$[0-9]+\.[0-9]{2}$ ]]; then
    assert_test "test1" "true" "Script executes correctly in tmux environment"
else
    assert_test "test1" "false" "Expected dollar format, got: $result"
fi

# Test 2: tmux options configuration
echo
echo "Test 2: tmux options reading"

tmux set-option -g @ccusage_subscription_amount 150
tmux set-option -g @ccusage_warning_threshold 75
tmux set-option -g @ccusage_cache_ttl 45

sub_amount=$(tmux show-option -gv @ccusage_subscription_amount)
warn_threshold=$(tmux show-option -gv @ccusage_warning_threshold)

echo "Set subscription amount: $sub_amount"
echo "Set warning threshold: $warn_threshold"

if [[ "$sub_amount" == "150" ]] && [[ "$warn_threshold" == "75" ]]; then
    assert_test "test2" "true" "tmux options set and read correctly"
else
    assert_test "test2" "false" "tmux options not working correctly"
fi

# Test 3: Script reads tmux options
echo
echo "Test 3: Script using tmux options"

percentage_result=$(./tmux-ccusage.sh percentage)
echo "Percentage with tmux subscription option: $percentage_result"

if [[ "$percentage_result" =~ ^[0-9]+\.[0-9]+%$ ]] || [[ "$percentage_result" == "N/A" ]]; then
    assert_test "test3" "true" "Script correctly reads tmux subscription option"
else
    assert_test "test3" "false" "Script failed to use tmux options, got: $percentage_result"
fi

# Test 4: Status bar configuration
echo
echo "Test 4: Status bar integration"

tmux set-option -g status-right "#($PWD/tmux-ccusage.sh) | %H:%M"
tmux set-option -g status-right-length 80

status_right=$(tmux show-option -gv status-right)
status_length=$(tmux show-option -gv status-right-length)

echo "Status right setting: $status_right"
echo "Status length: $status_length"

if [[ "$status_right" == *"tmux-ccusage.sh"* ]] && [[ "$status_length" == "80" ]]; then
    assert_test "test4" "true" "Status bar configured correctly"
else
    assert_test "test4" "false" "Status bar configuration failed"
fi

# Test 5: Multiple format support
echo
echo "Test 5: Multiple format support in tmux"

formats=("daily_today" "total" "both" "percentage" "remaining")
format_success=true

for format in "${formats[@]}"; do
    format_result=$(./tmux-ccusage.sh "$format")
    echo "$format: $format_result"
    
    if [[ -z "$format_result" ]]; then
        format_success=false
        echo "  ✗ Format $format failed"
    else
        echo "  ✓ Format $format working"
    fi
done

if [ "$format_success" = true ]; then
    assert_test "test5" "true" "All formats work in tmux environment"
else
    assert_test "test5" "false" "Some formats failed in tmux environment"
fi

# Test 6: Different tmux option configurations
echo
echo "Test 6: Different tmux option configurations"

# Set a different global option value
original_amount=$(tmux show-option -gv @ccusage_subscription_amount)
tmux set-option -g @ccusage_subscription_amount 300

new_percentage=$(./tmux-ccusage.sh percentage)
echo "Percentage with 300 subscription: $new_percentage"

# Restore original
tmux set-option -g @ccusage_subscription_amount "$original_amount"
restored_percentage=$(./tmux-ccusage.sh percentage)
echo "Restored percentage: $restored_percentage"

if [[ "$new_percentage" != "$restored_percentage" ]]; then
    assert_test "test6" "true" "Dynamic tmux options configuration working"
else
    assert_test "test6" "false" "Dynamic tmux options not working properly"
fi

# Test 7: Cache behavior in tmux
echo
echo "Test 7: Cache behavior in tmux environment"

# Clear cache
rm -rf ~/.cache/tmux-ccusage/

# First execution
start_time=$(date +%s)
cache_result1=$(./tmux-ccusage.sh)
end_time=$(date +%s)
first_duration=$((end_time - start_time))

# Second execution (should use cache)
start_time=$(date +%s)
cache_result2=$(./tmux-ccusage.sh)
end_time=$(date +%s)
second_duration=$((end_time - start_time))

echo "First run (${first_duration}s): $cache_result1"
echo "Second run (${second_duration}s): $cache_result2"

if [[ -f ~/.cache/tmux-ccusage/ccusage.json ]] && [[ "$cache_result1" == "$cache_result2" ]]; then
    assert_test "test7" "true" "Cache working correctly in tmux environment"
else
    assert_test "test7" "false" "Cache not working in tmux environment"
fi

# Test 8: Real tmux run-shell execution
echo
echo "Test 8: tmux run-shell execution"

# Test actual run-shell command
run_shell_result=$(tmux run-shell "$PWD/tmux-ccusage.sh" 2>/dev/null || echo "FAILED")
echo "run-shell result: $run_shell_result"

if [[ "$run_shell_result" != "FAILED" ]] && [[ -n "$run_shell_result" ]]; then
    assert_test "test8" "true" "tmux run-shell execution working"
else
    assert_test "test8" "false" "tmux run-shell execution failed"
fi

# Cleanup
echo
echo "Cleaning up test sessions..."
tmux kill-session -t tmux-test-main 2>/dev/null || true
tmux kill-session -t tmux-test-options 2>/dev/null || true

# Summary
echo
echo "=== tmux Integration Test Summary ==="
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
    echo "✓ All tmux integration tests passed!"
    exit 0
else
    echo "✗ Some tmux integration tests failed"
    exit 1
fi