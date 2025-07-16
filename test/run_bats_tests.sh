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

# Run all bats tests
echo "Running Bats tests..."
echo "===================="

cd "$PROJECT_DIR"

# Run tests and capture results
if bats test/bats/*.bats --tap; then
    echo ""
    echo "All tests passed!"
else
    echo ""
    echo "Some tests failed!"
    exit 1
fi