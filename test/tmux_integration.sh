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
    
    # Test the script directly
    echo -e "\n${BOLD}Debug: Testing tmux-ccusage.sh directly...${NC}"
    echo -e "  Script path: $PROJECT_DIR/tmux-ccusage.sh"
    echo -e "  PATH: $PATH"
    echo -e "  TMUX_TEST_MODE: $TMUX_TEST_MODE"
    
    # Test if ccusage is available
    if command -v ccusage &> /dev/null; then
        echo -e "  ccusage found at: $(which ccusage)"
        echo -e "  ccusage version: $(ccusage --version 2>&1 || echo 'version check failed')"
    else
        echo -e "${RED}  ccusage not found in PATH${NC}"
    fi
    
    # Try running the script directly
    echo -e "\n  Testing direct execution:"
    test_output=$("$PROJECT_DIR/tmux-ccusage.sh" daily_today 2>&1)
    echo -e "  Output: '$test_output'"
    echo -e "  Exit code: $?"
else
    echo -e "${RED}✗ Plugin failed to load${NC}"
    # Try to see all global options
    echo -e "${YELLOW}All user options:${NC}"
    tmux show-options -g | grep "@ccusage" || echo "No @ccusage options found"
fi

# Test 1: Check if user options are set and work via status line
echo -e "\n${BOLD}Test 1: Testing format options via status line...${NC}"
OPTIONS=(
    "@ccusage_daily_today"
    "@ccusage_daily_total"
    "@ccusage_monthly_current"
    "@ccusage_remaining"
    "@ccusage_percentage"
    "@ccusage_status"
)

FAILED=0
for option in "${OPTIONS[@]}"; do
    value=$(tmux show-option -gqv "$option" 2>/dev/null)
    if [[ -z "$value" ]]; then
        echo -e "${RED}✗ Option $option not set${NC}"
        FAILED=1
    else
        echo -e "\nTesting $option:"
        echo -e "  Command: $value"
        
        # Set this as the status-right and force a refresh
        tmux set-option -g status-right "$value"
        tmux refresh-client -S 2>/dev/null || true
        sleep 0.5
        
        # Get the rendered status
        rendered_status=$(tmux display-message -p "#{status-right}" 2>&1)
        echo -e "  Status shows: $rendered_status"
        
        # Check if it rendered something meaningful
        if [[ "$rendered_status" == "$value" ]]; then
            echo -e "${YELLOW}  ⚠ Status not rendered (shows raw command)${NC}"
            # Test directly
            format="${option##*_}"
            echo -e "  Testing directly with format: $format"
            direct_output=$(PATH="$HOME/.local/bin:$PATH" TMUX_TEST_MODE=1 "$PROJECT_DIR/tmux-ccusage.sh" "$format" 2>&1)
            echo -e "  Direct output: $direct_output"
            FAILED=1
        elif [[ -z "$rendered_status" ]] || [[ "$rendered_status" == " " ]]; then
            echo -e "${YELLOW}  ⚠ Status rendered empty${NC}"
            FAILED=1
        else
            echo -e "${GREEN}  ✓ Status rendered: $rendered_status${NC}"
        fi
    fi
done

# Test 2: Test with subscription configuration
echo -e "\n${BOLD}Test 2: Testing with subscription configuration...${NC}"
tmux set-option -g @ccusage_subscription_amount 200
bash "$PROJECT_DIR/tmux-ccusage.tmux"
sleep 1

# Check remaining format
remaining_cmd=$(tmux show-option -gqv "@ccusage_remaining" 2>/dev/null)
export PATH="$HOME/.local/bin:$PATH"
export TMUX_TEST_MODE=1
remaining=$(eval "$remaining_cmd" 2>&1)
if [[ "$remaining" =~ \$[0-9]+\.[0-9]+/\$[0-9]+ ]]; then
    echo -e "${GREEN}✓ Remaining format works: $remaining${NC}"
else
    echo -e "${RED}✗ Remaining format failed: $remaining${NC}"
    FAILED=1
fi

# Check percentage format  
percentage_cmd=$(tmux show-option -gqv "@ccusage_percentage" 2>/dev/null)
export PATH="$HOME/.local/bin:$PATH"
export TMUX_TEST_MODE=1
percentage=$(eval "$percentage_cmd" 2>&1)
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
    bash "$PROJECT_DIR/tmux-ccusage.tmux"
    sleep 1
    
    cmd=$(tmux show-option -gqv "@ccusage_daily_today" 2>/dev/null)
    export PATH="$HOME/.local/bin:$PATH"
    export TMUX_TEST_MODE=1
    value=$(eval "$cmd" 2>&1)
    if [[ "$value" =~ ^\$[0-9]+\.[0-9]{2}$ ]]; then
        echo -e "${GREEN}✓ Report type '$report_type' works: $value${NC}"
    else
        echo -e "${RED}✗ Report type '$report_type' failed: $value${NC}"
        FAILED=1
    fi
done

# Test 4: Test status bar integration
echo -e "\n${BOLD}Test 4: Testing status bar integration...${NC}"
# Get the command for daily_today
cmd=$(tmux show-option -gqv "@ccusage_daily_today" 2>/dev/null)
tmux set-option -g status-right "Claude: $cmd"
status_right=$(tmux show-option -gv status-right 2>/dev/null || echo "ERROR")
if [[ "$status_right" == *"tmux-ccusage.sh"* ]]; then
    echo -e "${GREEN}✓ Status bar integration successful${NC}"
    
    # Force status refresh (skip if no client attached)
    tmux refresh-client -S 2>/dev/null || true
    sleep 1
    
    # Check if the value is actually displayed
    export PATH="$HOME/.local/bin:$PATH"
    export TMUX_TEST_MODE=1
    actual_value=$(eval "$cmd" 2>&1)
    if [[ "$actual_value" =~ ^\$[0-9]+\.[0-9]{2}$ ]]; then
        echo -e "${GREEN}✓ Status bar value: $actual_value${NC}"
    else
        echo -e "${YELLOW}⚠ Status bar value: $actual_value${NC}"
    fi
else
    echo -e "${RED}✗ Status bar integration failed${NC}"
    FAILED=1
fi

# Test 5: Test cache functionality
echo -e "\n${BOLD}Test 5: Testing cache functionality...${NC}"
# First call
cmd=$(tmux show-option -gqv "@ccusage_daily_today" 2>/dev/null)
export PATH="$HOME/.local/bin:$PATH"
export TMUX_TEST_MODE=1

if command -v gdate &> /dev/null; then
    # macOS with GNU coreutils
    start_time=$(gdate +%s%N)
    value1=$(eval "$cmd" 2>&1)
    end_time=$(gdate +%s%N)
    first_duration=$((($end_time - $start_time) / 1000000))
    
    # Second call (should use cache)
    start_time=$(gdate +%s%N)
    value2=$(eval "$cmd" 2>&1)
    end_time=$(gdate +%s%N)
    second_duration=$((($end_time - $start_time) / 1000000))
    
    echo -e "  First call: ${first_duration}ms, Second call: ${second_duration}ms"
else
    # Fallback for systems without nanosecond precision
    value1=$(eval "$cmd" 2>&1)
    sleep 0.1
    value2=$(eval "$cmd" 2>&1)
fi

if [[ "$value1" == "$value2" ]]; then
    echo -e "${GREEN}✓ Cache returns consistent values${NC}"
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