#!/usr/bin/env bash

# Tmux integration tests for tmux-ccusage
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ -n "${GITHUB_ACTIONS:-}" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

# Test session name
TEST_SESSION="tmux-ccusage-test-$$"

# Cleanup function
cleanup() {
    tmux kill-session -t "$TEST_SESSION" 2>/dev/null || true
}
trap cleanup EXIT

echo -e "${BOLD}${BLUE}Running tmux integration tests...${NC}"
echo -e "${BOLD}${BLUE}==================================${NC}"

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}Error: tmux is not installed${NC}"
    exit 1
fi

# Ensure tmux server is running
tmux start-server 2>/dev/null || true

# Create a new tmux session
echo -e "\n${BOLD}Creating test tmux session...${NC}"
tmux new-session -d -s "$TEST_SESSION" -x 80 -y 24

# Source the tmux-ccusage plugin
echo -e "${BOLD}Loading tmux-ccusage plugin...${NC}"
tmux send-keys -t "$TEST_SESSION" "tmux source-file '$PROJECT_DIR/tmux-ccusage.tmux'" C-m
sleep 1

# Test 1: Check if format variables are set
echo -e "\n${BOLD}Test 1: Checking format variables...${NC}"
FORMATS=(
    "ccusage_daily_today"
    "ccusage_daily_total"
    "ccusage_monthly_current"
    "ccusage_remaining"
    "ccusage_percentage"
    "ccusage_status"
)

FAILED=0
for format in "${FORMATS[@]}"; do
    value=$(tmux display-message -p "#{$format}" 2>/dev/null || echo "ERROR")
    if [[ "$value" == "ERROR" ]] || [[ -z "$value" ]]; then
        echo -e "${RED}✗ Format #{$format} not available${NC}"
        FAILED=1
    else
        echo -e "${GREEN}✓ Format #{$format} = $value${NC}"
    fi
done

# Test 2: Test with subscription configuration
echo -e "\n${BOLD}Test 2: Testing with subscription configuration...${NC}"
tmux set-option -g @ccusage_subscription_amount 200
tmux send-keys -t "$TEST_SESSION" "tmux source-file '$PROJECT_DIR/tmux-ccusage.tmux'" C-m
sleep 1

# Check remaining format
remaining=$(tmux display-message -p "#{ccusage_remaining}" 2>/dev/null || echo "ERROR")
if [[ "$remaining" =~ \$[0-9]+\.[0-9]+/\$[0-9]+ ]]; then
    echo -e "${GREEN}✓ Remaining format works: $remaining${NC}"
else
    echo -e "${RED}✗ Remaining format failed: $remaining${NC}"
    FAILED=1
fi

# Check percentage format
percentage=$(tmux display-message -p "#{ccusage_percentage}" 2>/dev/null || echo "ERROR")
if [[ "$percentage" =~ [0-9]+\.[0-9]+% ]] || [[ "$percentage" == "N/A" ]]; then
    echo -e "${GREEN}✓ Percentage format works: $percentage${NC}"
else
    echo -e "${RED}✗ Percentage format failed: $percentage${NC}"
    FAILED=1
fi

# Test 3: Test different report types
echo -e "\n${BOLD}Test 3: Testing different report types...${NC}"
REPORT_TYPES=("daily" "monthly")

for report_type in "${REPORT_TYPES[@]}"; do
    tmux set-option -g @ccusage_report_type "$report_type"
    tmux send-keys -t "$TEST_SESSION" "tmux source-file '$PROJECT_DIR/tmux-ccusage.tmux'" C-m
    sleep 1
    
    value=$(tmux display-message -p "#{ccusage_daily_today}" 2>/dev/null || echo "ERROR")
    if [[ "$value" =~ ^\$[0-9]+\.[0-9]{2}$ ]]; then
        echo -e "${GREEN}✓ Report type '$report_type' works: $value${NC}"
    else
        echo -e "${RED}✗ Report type '$report_type' failed: $value${NC}"
        FAILED=1
    fi
done

# Test 4: Test status bar integration
echo -e "\n${BOLD}Test 4: Testing status bar integration...${NC}"
tmux set-option -g status-right "Claude: #{ccusage_daily_today}"
status_right=$(tmux show-option -gv status-right 2>/dev/null || echo "ERROR")
if [[ "$status_right" == *"#{ccusage_daily_today}"* ]]; then
    echo -e "${GREEN}✓ Status bar integration successful${NC}"
    
    # Get the actual rendered value
    rendered=$(tmux display-message -p "#{status-right}" 2>/dev/null || echo "ERROR")
    if [[ "$rendered" =~ Claude:.*\$[0-9]+\.[0-9]{2} ]]; then
        echo -e "${GREEN}✓ Status bar renders correctly: $rendered${NC}"
    else
        echo -e "${YELLOW}⚠ Status bar rendering: $rendered${NC}"
    fi
else
    echo -e "${RED}✗ Status bar integration failed${NC}"
    FAILED=1
fi

# Test 5: Test cache functionality
echo -e "\n${BOLD}Test 5: Testing cache functionality...${NC}"
# First call
start_time=$(date +%s%N)
value1=$(tmux display-message -p "#{ccusage_daily_today}" 2>/dev/null)
end_time=$(date +%s%N)
first_duration=$((($end_time - $start_time) / 1000000))

# Second call (should use cache)
start_time=$(date +%s%N)
value2=$(tmux display-message -p "#{ccusage_daily_today}" 2>/dev/null)
end_time=$(date +%s%N)
second_duration=$((($end_time - $start_time) / 1000000))

if [[ "$value1" == "$value2" ]]; then
    echo -e "${GREEN}✓ Cache returns consistent values${NC}"
    echo -e "  First call: ${first_duration}ms, Second call: ${second_duration}ms"
else
    echo -e "${RED}✗ Cache inconsistency detected${NC}"
    FAILED=1
fi

# Summary
echo -e "\n${BOLD}${BLUE}Test Summary${NC}"
echo -e "${BOLD}${BLUE}============${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ All tmux integration tests passed!${NC}"
    exit 0
else
    echo -e "${RED}${BOLD}✗ Some tmux integration tests failed!${NC}"
    exit 1
fi