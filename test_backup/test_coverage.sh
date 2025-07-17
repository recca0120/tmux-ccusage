#!/usr/bin/env bash

# Simple coverage report for tmux-ccusage

echo "=== Code Coverage Report ==="
echo ""

# Count lines in each script
declare -A file_lines
declare -A file_functions

files=(
    "tmux-ccusage.sh"
    "scripts/json_parser.sh"
    "scripts/cache.sh"
    "scripts/formatter.sh"
)

total_lines=0
total_functions=0

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        # Count non-empty, non-comment lines
        lines=$(grep -v '^[[:space:]]*#' "$file" | grep -v '^[[:space:]]*$' | wc -l)
        file_lines["$file"]=$lines
        total_lines=$((total_lines + lines))
        
        # Count functions
        functions=$(grep -c '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*()' "$file" || true)
        file_functions["$file"]=$functions
        total_functions=$((total_functions + functions))
    fi
done

echo "File Statistics:"
echo "================"
printf "%-30s %10s %10s\n" "File" "Lines" "Functions"
printf "%-30s %10s %10s\n" "----" "-----" "---------"

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        printf "%-30s %10d %10d\n" "$file" "${file_lines[$file]}" "${file_functions[$file]}"
    fi
done

printf "%-30s %10s %10s\n" "----" "-----" "---------"
printf "%-30s %10d %10d\n" "Total" "$total_lines" "$total_functions"

echo ""
echo "Test Statistics:"
echo "================"

# Count test assertions
test_files=(test/test_*.sh)
total_tests=0

for test_file in "${test_files[@]}"; do
    if [ -f "$test_file" ]; then
        tests=$(grep -c 'assert_equals' "$test_file" || true)
        total_tests=$((total_tests + tests))
        printf "%-30s %10d assertions\n" "$(basename "$test_file")" "$tests"
    fi
done

echo ""
printf "Total test assertions: %d\n" "$total_tests"

# Simple coverage estimation
if [ $total_functions -gt 0 ]; then
    # Assume each test covers about 2 functions on average
    estimated_coverage=$((total_tests * 2 * 100 / total_functions))
    if [ $estimated_coverage -gt 100 ]; then
        estimated_coverage=100
    fi
    echo ""
    echo "Estimated function coverage: ${estimated_coverage}%"
fi

echo ""
echo "Note: This is a simple line count report."
echo "For detailed coverage, use bashcov or kcov."