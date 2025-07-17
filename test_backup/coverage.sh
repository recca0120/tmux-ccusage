#!/usr/bin/env bash

# Coverage report script for tmux-ccusage

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COVERAGE_DIR="$PROJECT_DIR/coverage"

# Check if kcov is installed
if ! command -v kcov &> /dev/null; then
    echo "kcov is not installed. Please install kcov for coverage reports."
    echo "Ubuntu: sudo apt-get install kcov"
    echo "macOS: brew install kcov"
    exit 1
fi

# Clean previous coverage
rm -rf "$COVERAGE_DIR"
mkdir -p "$COVERAGE_DIR"

# Run tests with coverage
echo "Running tests with coverage..."

# List of scripts to test
SCRIPTS=(
    "tmux-ccusage.sh"
    "scripts/json_parser.sh"
    "scripts/cache.sh"
    "scripts/formatter.sh"
)

# Run coverage for each script
for script in "${SCRIPTS[@]}"; do
    if [ -f "$PROJECT_DIR/$script" ]; then
        echo "Testing $script..."
        script_name=$(basename "$script" .sh)
        kcov --exclude-pattern=/usr/,/tmp/,test/ \
             "$COVERAGE_DIR/$script_name" \
             "$PROJECT_DIR/test/test_runner.sh"
    fi
done

# Merge coverage reports
echo "Merging coverage reports..."
kcov --merge "$COVERAGE_DIR/merged" "$COVERAGE_DIR"/*

# Generate summary
echo ""
echo "Coverage Summary:"
echo "================="

# Extract coverage percentage from kcov output
if [ -f "$COVERAGE_DIR/merged/index.html" ]; then
    # Try to extract coverage from HTML
    coverage=$(grep -o '[0-9]\+\.[0-9]\+%' "$COVERAGE_DIR/merged/index.html" | head -1 || echo "N/A")
    echo "Overall coverage: $coverage"
    echo ""
    echo "Detailed report: $COVERAGE_DIR/merged/index.html"
else
    echo "Coverage report generation failed"
fi

# Create simple text report
echo ""
echo "Generating text report..."
find "$PROJECT_DIR/scripts" -name "*.sh" -o -name "tmux-ccusage.sh" | while read -r file; do
    if [ -f "$file" ]; then
        total_lines=$(wc -l < "$file")
        # This is a simple approximation - real coverage would need execution tracking
        echo "$(basename "$file"): $total_lines lines"
    fi
done