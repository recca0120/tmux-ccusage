#!/usr/bin/env bash

# Run all Bats tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo "Bats is not installed. Installing..."
    
    # Try to install bats
    if command -v npm &> /dev/null; then
        npm install -g bats
    elif command -v brew &> /dev/null; then
        brew install bats-core
    else
        echo "Please install Bats:"
        echo "  npm install -g bats"
        echo "  or"
        echo "  brew install bats-core"
        exit 1
    fi
fi

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Disable colors only if NO_COLOR is set or not a terminal
# GitHub Actions supports ANSI colors
if [ -n "${NO_COLOR:-}" ] || ([ ! -t 1 ] && [ -z "${GITHUB_ACTIONS:-}" ]); then
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

# Run all bats tests
echo -e "${BOLD}${BLUE}Running Bats tests...${NC}"
echo -e "${BOLD}${BLUE}====================${NC}"

cd "$PROJECT_DIR"

# Choose formatter based on environment
if [ -n "${GITHUB_ACTIONS:-}" ]; then
    # Use pretty formatter for GitHub Actions
    FORMATTER="--formatter pretty"
else
    # Use TAP formatter for other environments
    FORMATTER="--tap"
fi

# Run tests and capture results
if bats test/bats/*.bats $FORMATTER; then
    echo ""
    echo -e "${GREEN}${BOLD}✓ All tests passed!${NC}"
else
    echo ""
    echo -e "${RED}${BOLD}✗ Some tests failed!${NC}"
    exit 1
fi