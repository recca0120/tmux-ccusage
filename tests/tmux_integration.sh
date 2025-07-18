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

# Set up environment
export PATH="$HOME/.local/bin:$PATH"
export TMUX_TEST_MODE=1

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

# Enable status line
tmux set-option -t "$TEST_SESSION" status on
tmux set-option -t "$TEST_SESSION" status-interval 1

# Source the tmux-ccusage plugin
echo -e "${BOLD}Loading tmux-ccusage plugin...${NC}"
# Debug: Check if plugin file exists
if [ ! -f "$PROJECT_DIR/tmux-ccusage.tmux" ]; then
    echo -e "${RED}Error: Plugin file not found at $PROJECT_DIR/tmux-ccusage.tmux${NC}"
    exit 1
fi
# Execute the plugin file as a bash script
bash "$PROJECT_DIR/tmux-ccusage.tmux"
sleep 1

# Debug: Check if any options were set
echo -e "${BOLD}Debug: Checking if plugin loaded...${NC}"
test_option=$(tmux show-option -gqv "@ccusage_daily_today" 2>/dev/null)
if [ -n "$test_option" ]; then
    echo -e "${GREEN}✓ Plugin loaded successfully${NC}"
else
    echo -e "${RED}✗ Plugin failed to load${NC}"
    # Try to see all global options
    echo -e "${YELLOW}All user options:${NC}"
    tmux show-options -g | grep "@ccusage" || echo "No @ccusage options found"
    exit 1
fi

# Test 1: Check if format commands work
echo -e "\n${BOLD}Test 1: Testing format commands...${NC}"
FORMATS=(
    "daily_today|Should show today's cost"
    "daily_total|Should show daily total"
    "monthly_current|Should show current month"
    "remaining|Should show remaining amount"
    "percentage|Should show usage percentage"
    "status|Should show status"
)

FAILED=0
for format_desc in "${FORMATS[@]}"; do
    format="${format_desc%|*}"
    desc="${format_desc#*|}"
    
    echo -e "\nTesting format: $format"
    echo -e "  Description: $desc"
    
    # Test the command directly
    output=$(PATH="$HOME/.local/bin:$PATH" TMUX_TEST_MODE=1 "$PROJECT_DIR/tmux-ccusage.sh" "$format" 2>&1)
    exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo -e "${RED}  ✗ Command failed (exit code: $exit_code)${NC}"
        echo -e "  Error: $output"
        FAILED=1
    elif [[ -z "$output" ]]; then
        echo -e "${RED}  ✗ Command returned empty${NC}"
        FAILED=1
    else
        echo -e "${GREEN}  ✓ Output: $output${NC}"
        
        # Validate output format
        case "$format" in
            remaining)
                if [[ "$output" =~ ^\$[0-9]+(\.[0-9]+)?/\$[0-9]+ ]]; then
                    echo -e "${GREEN}  ✓ Format validated${NC}"
                else
                    echo -e "${YELLOW}  ⚠ Unexpected format${NC}"
                fi
                ;;
            percentage)
                if [[ "$output" =~ ^[0-9]+(\.[0-9]+)?%$ ]] || [[ "$output" == "N/A" ]]; then
                    echo -e "${GREEN}  ✓ Format validated${NC}"
                else
                    echo -e "${YELLOW}  ⚠ Unexpected format${NC}"
                fi
                ;;
            *)
                if [[ "$output" =~ ^\$[0-9]+\.[0-9]{2} ]]; then
                    echo -e "${GREEN}  ✓ Format validated${NC}"
                fi
                ;;
        esac
    fi
done

# Test 2: Test with subscription configuration
echo -e "\n${BOLD}Test 2: Testing with subscription configuration...${NC}"
tmux set-option -g @ccusage_subscription_amount 200
bash "$PROJECT_DIR/tmux-ccusage.tmux"
sleep 1

# Test remaining format with subscription
echo -e "\n  Testing remaining with subscription:"
output=$(PATH="$HOME/.local/bin:$PATH" TMUX_TEST_MODE=1 CCUSAGE_SUBSCRIPTION_AMOUNT=200 "$PROJECT_DIR/tmux-ccusage.sh" remaining 2>&1)
if [[ "$output" =~ ^\$[0-9]+(\.[0-9]+)?/\$200$ ]]; then
    echo -e "${GREEN}  ✓ Remaining format works: $output${NC}"
else
    echo -e "${RED}  ✗ Remaining format failed: $output${NC}"
    FAILED=1
fi

# Test percentage format with subscription
echo -e "\n  Testing percentage with subscription:"
output=$(PATH="$HOME/.local/bin:$PATH" TMUX_TEST_MODE=1 CCUSAGE_SUBSCRIPTION_AMOUNT=200 "$PROJECT_DIR/tmux-ccusage.sh" percentage 2>&1)
if [[ "$output" =~ ^[0-9]+(\.[0-9]+)?%$ ]]; then
    echo -e "${GREEN}  ✓ Percentage format works: $output${NC}"
else
    echo -e "${RED}  ✗ Percentage format failed: $output${NC}"
    FAILED=1
fi

# Test 3: Test different report types
echo -e "\n${BOLD}Test 3: Testing different report types...${NC}"
REPORT_TYPES=("daily" "monthly")

for report_type in "${REPORT_TYPES[@]}"; do
    echo -e "\n  Testing report type: $report_type"
    tmux set-option -g @ccusage_report_type "$report_type"
    
    output=$(PATH="$HOME/.local/bin:$PATH" TMUX_TEST_MODE=1 CCUSAGE_REPORT_TYPE="$report_type" "$PROJECT_DIR/tmux-ccusage.sh" daily_today 2>&1)
    if [[ "$output" =~ ^\$[0-9]+\.[0-9]{2}$ ]]; then
        echo -e "${GREEN}  ✓ Report type '$report_type' works: $output${NC}"
    else
        echo -e "${RED}  ✗ Report type '$report_type' failed: $output${NC}"
        FAILED=1
    fi
done

# Test 4: Test tmux option retrieval
echo -e "\n${BOLD}Test 4: Testing tmux option retrieval...${NC}"
option_value=$(tmux show-option -gqv "@ccusage_daily_today" 2>/dev/null)
if [[ "$option_value" =~ tmux-ccusage\.sh ]]; then
    echo -e "${GREEN}✓ Tmux option contains correct script path${NC}"
else
    echo -e "${RED}✗ Tmux option incorrect: $option_value${NC}"
    FAILED=1
fi

# Test 5: Test cache functionality
echo -e "\n${BOLD}Test 5: Testing cache functionality...${NC}"
# First call
value1=$(PATH="$HOME/.local/bin:$PATH" TMUX_TEST_MODE=1 "$PROJECT_DIR/tmux-ccusage.sh" daily_today 2>&1)
sleep 0.1
# Second call (should use cache)
value2=$(PATH="$HOME/.local/bin:$PATH" TMUX_TEST_MODE=1 "$PROJECT_DIR/tmux-ccusage.sh" daily_today 2>&1)

if [[ "$value1" == "$value2" ]]; then
    echo -e "${GREEN}✓ Cache returns consistent values${NC}"
    echo -e "  Both calls returned: $value1"
else
    echo -e "${RED}✗ Cache inconsistency detected${NC}"
    echo -e "  First: $value1"
    echo -e "  Second: $value2"
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