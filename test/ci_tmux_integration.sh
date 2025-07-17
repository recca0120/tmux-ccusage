#!/usr/bin/env bash

# CI-Optimized tmux Integration Tests
# 
# This separate test script was created to address reliability issues when running
# tmux integration tests in CI/CD environments (GitHub Actions).
# 
# Why this exists:
# 1. CI environments often run headless without a proper terminal
# 2. tmux run-shell command behaves differently in non-interactive environments
# 3. Some tmux features require a real TTY which CI doesn't always provide
# 4. Simplified test set focuses on core functionality that works reliably in CI
#
# Differences from test_tmux_integration.sh:
# - Reduced test count (5 vs 8) for faster CI runs
# - Removed tests that require complex tmux session management
# - Simplified tmux setup using a single persistent session
# - More lenient timing to account for CI environment variability

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "=== CI-Optimized tmux Integration Tests ==="

# Start a simple tmux server
tmux new-session -d -s ci-test 'sleep 3600'
sleep 1

# Get tmux socket path
tmux_socket=$(tmux display-message -p "#{socket_path}")
export TMUX="$tmux_socket,1234,0"

echo "tmux server started, TMUX env: $TMUX"

# Test 1: Script execution in tmux environment
echo
echo "Test 1: Script execution with tmux environment"
result=$(./tmux-ccusage.sh)
echo "Result: $result"
if [[ "$result" =~ ^\$[0-9]+\.[0-9]{2}$ ]]; then
    echo "✓ Test 1 PASSED"
else
    echo "✗ Test 1 FAILED"
    exit 1
fi

# Test 2: tmux options
echo
echo "Test 2: tmux options handling"
tmux set-option -g @ccusage_subscription_amount 250
tmux set-option -g @ccusage_cache_ttl 45

# Read back options
sub=$(tmux show-option -gv @ccusage_subscription_amount)
ttl=$(tmux show-option -gv @ccusage_cache_ttl)
echo "Subscription: $sub, TTL: $ttl"

# Test script uses the option
percentage=$(./tmux-ccusage.sh percentage)
echo "Percentage: $percentage"

if [[ "$percentage" =~ ^[0-9]+\.[0-9]+%$ ]] || [[ "$percentage" == "N/A" ]]; then
    echo "✓ Test 2 PASSED"
else
    echo "✗ Test 2 FAILED"
    exit 1
fi

# Test 3: All output formats
echo
echo "Test 3: Output formats"
formats=("daily_today" "total" "both" "percentage" "remaining" "status")
all_passed=true

for format in "${formats[@]}"; do
    result=$(./tmux-ccusage.sh "$format")
    echo "$format: $result"
    if [[ -z "$result" ]]; then
        all_passed=false
    fi
done

if [ "$all_passed" = true ]; then
    echo "✓ Test 3 PASSED"
else
    echo "✗ Test 3 FAILED"
    exit 1
fi

# Test 4: Status bar configuration
echo
echo "Test 4: Status bar configuration"
tmux set-option -g status-right "#($PWD/tmux-ccusage.sh) | %H:%M"
status=$(tmux show-option -gv status-right)
echo "Status right: $status"

if [[ "$status" == *"tmux-ccusage.sh"* ]]; then
    echo "✓ Test 4 PASSED"
else
    echo "✗ Test 4 FAILED"
    exit 1
fi

# Test 5: Cache behavior
echo
echo "Test 5: Cache behavior"
rm -rf ~/.cache/tmux-ccusage/
first=$(./tmux-ccusage.sh)
sleep 1
second=$(./tmux-ccusage.sh)

if [[ -f ~/.cache/tmux-ccusage/ccusage.json ]] && [[ "$first" == "$second" ]]; then
    echo "✓ Test 5 PASSED"
else
    echo "✗ Test 5 FAILED"
    exit 1
fi

# Cleanup
tmux kill-server 2>/dev/null || true

echo
echo "=== All CI tmux tests passed! ==="