#!/usr/bin/env bash

# Test helper for tmux-ccusage Bats tests

# Get the project root directory
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source the main modules
source "$PROJECT_ROOT/scripts/json_parser.sh"
source "$PROJECT_ROOT/scripts/formatter.sh"
source "$PROJECT_ROOT/scripts/cache.sh"

# Set up test environment
export TMUX_TEST_MODE=1
export CCUSAGE_CACHE_DIR="$BATS_TEST_TMPDIR/cache"

# Mock ccusage command
ccusage() {
    case "$1" in
        "--version"|"-v")
            echo "15.3.1"
            ;;
        "daily"|"monthly"|"session"|"blocks"|*)
            if [[ "$@" == *"-j"* ]] || [[ "$@" == *"--json"* ]]; then
                echo '{"daily":[{"date":"2025-07-17","totalCost":17.96}],"totals":{"totalCost":160.55}}'
            else
                echo "Daily usage report"
            fi
            ;;
    esac
}
export -f ccusage

# Common test data
export MOCK_JSON='{"daily":[{"date":"2025-07-17","totalCost":17.96}],"totals":{"totalCost":160.55}}'
export MOCK_MONTHLY_JSON='{"monthly":[{"month":"2025-07","totalCost":450.25}]}'
export MOCK_MULTI_DAY_JSON='{
  "daily": [
    {"date": "2025-07-15", "totalCost": 3.20},
    {"date": "2025-07-16", "totalCost": 130.45},
    {"date": "2025-07-17", "totalCost": 17.96}
  ],
  "totals": {"totalCost": 160.55}
}'