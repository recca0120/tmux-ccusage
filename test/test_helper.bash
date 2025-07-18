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
        "monthly")
            # Check if offline mode is requested and no cache exists
            if [[ "$@" == *"--offline"* ]] && [ ! -f "$CCUSAGE_CACHE_DIR/ccusage.json" ]; then
                # Simulate error when offline with no cache
                echo "Error: Offline mode requested but no cached data available" >&2
                return 1
            fi
            
            if [[ "$@" == *"-j"* ]] || [[ "$@" == *"--json"* ]]; then
                # Return multi-month data to test parsing of last entry
                echo '{
                  "monthly": [
                    {"month": "2025-05", "totalCost": 120.50},
                    {"month": "2025-06", "totalCost": 380.75},
                    {"month": "2025-07", "totalCost": 450.25}
                  ],
                  "totals": {"totalCost": 951.50}
                }'
            else
                echo "Monthly usage report"
            fi
            ;;
        "daily"|"session"|"blocks"|*)
            # Check if offline mode is requested and no cache exists
            if [[ "$@" == *"--offline"* ]] && [ ! -f "$CCUSAGE_CACHE_DIR/ccusage.json" ]; then
                # Simulate error when offline with no cache
                echo "Error: Offline mode requested but no cached data available" >&2
                return 1
            fi
            
            if [[ "$@" == *"-j"* ]] || [[ "$@" == *"--json"* ]]; then
                # Return multi-day data to test parsing of last entry
                echo '{
                  "daily": [
                    {"date": "2025-07-14", "totalCost": 8.94},
                    {"date": "2025-07-15", "totalCost": 3.20},
                    {"date": "2025-07-16", "totalCost": 130.45},
                    {"date": "2025-07-17", "totalCost": 17.96}
                  ],
                  "totals": {"totalCost": 160.55}
                }'
            else
                echo "Daily usage report"
            fi
            ;;
    esac
}
export -f ccusage

# Common test data
export MOCK_JSON='{"daily":[{"date":"2025-07-17","totalCost":17.96}],"totals":{"totalCost":160.55}}'
export MOCK_MONTHLY_JSON='{
  "monthly": [
    {"month": "2025-05", "totalCost": 120.50},
    {"month": "2025-06", "totalCost": 380.75},
    {"month": "2025-07", "totalCost": 450.25}
  ],
  "totals": {"totalCost": 951.50}
}'
export MOCK_MULTI_DAY_JSON='{
  "daily": [
    {"date": "2025-07-14", "totalCost": 8.94},
    {"date": "2025-07-15", "totalCost": 3.20},
    {"date": "2025-07-16", "totalCost": 130.45},
    {"date": "2025-07-17", "totalCost": 17.96}
  ],
  "totals": {"totalCost": 160.55}
}'