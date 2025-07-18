#!/usr/bin/env bash

# Run all Bats tests for tmux-ccusage

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
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

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo -e "${RED}Error: Bats is not installed${NC}"
    echo "Please install Bats:"
    echo "  brew install bats-core  # macOS"
    echo "  npm install -g bats     # npm"
    echo "  apt-get install bats    # Ubuntu/Debian"
    exit 1
fi

# Set TERM if not set
if [ -z "${TERM:-}" ]; then
    export TERM=xterm-256color
fi

echo -e "${BOLD}${BLUE}Running tmux-ccusage tests...${NC}"
echo -e "${BOLD}${BLUE}=============================${NC}"

# Change to project directory
cd "$PROJECT_DIR"

# Run all test files
FAILED=0
for test_file in tests/*.bats; do
    if [ -f "$test_file" ]; then
        echo -e "\n${BOLD}Running $(basename "$test_file")${NC}"
        if bats "$test_file"; then
            echo -e "${GREEN}✓ $(basename "$test_file") passed${NC}"
        else
            echo -e "${RED}✗ $(basename "$test_file") failed${NC}"
            FAILED=1
        fi
    fi
done

echo -e "\n${BOLD}${BLUE}Test Summary${NC}"
echo -e "${BOLD}${BLUE}============${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}${BOLD}✗ Some tests failed!${NC}"
    exit 1
fi