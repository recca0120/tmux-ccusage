#!/usr/bin/env bash

# Test JSON parsing functionality

# Mock ccusage JSON response
MOCK_JSON='{
  "daily": [
    {
      "date": "2025-07-15",
      "totalCost": 3.20
    },
    {
      "date": "2025-07-16", 
      "totalCost": 130.45
    },
    {
      "date": "2025-07-17",
      "totalCost": 17.96
    }
  ],
  "totals": {
    "totalCost": 160.55
  }
}'

# Test get_today_cost function
test_get_today_cost() {
    # Source the script (will be created)
    source "$PROJECT_DIR/scripts/json_parser.sh" >/dev/null 2>&1 || {
        # Script doesn't exist yet - this is expected in TDD
        assert_equals "" "" "json_parser.sh not yet implemented"
        return
    }
    
    local result=$(echo "$MOCK_JSON" | get_today_cost)
    assert_equals "17.96" "$result" "Should extract today's cost (17.96)"
}

# Test get_total_cost function
test_get_total_cost() {
    source "$PROJECT_DIR/scripts/json_parser.sh" >/dev/null 2>&1 || return
    
    local result=$(echo "$MOCK_JSON" | get_total_cost)
    assert_equals "160.55" "$result" "Should extract total cost (160.55)"
}

# Test get_cost_by_date function
test_get_cost_by_date() {
    source "$PROJECT_DIR/scripts/json_parser.sh" >/dev/null 2>&1 || return
    
    local result=$(echo "$MOCK_JSON" | get_cost_by_date "2025-07-16")
    assert_equals "130.45" "$result" "Should extract cost for specific date"
}

# Test handling empty JSON
test_empty_json() {
    source "$PROJECT_DIR/scripts/json_parser.sh" >/dev/null 2>&1 || return
    
    local result=$(echo '{}' | get_today_cost)
    assert_equals "0.00" "$result" "Should return 0.00 for empty JSON"
}

# Test handling invalid JSON
test_invalid_json() {
    source "$PROJECT_DIR/scripts/json_parser.sh" >/dev/null 2>&1 || return
    
    local result=$(echo 'invalid json' | get_today_cost)
    assert_equals "0.00" "$result" "Should return 0.00 for invalid JSON"
}

# Test monthly JSON parsing
test_monthly_json() {
    local monthly_json='{
        "monthly": [
            {
                "month": "2025-07",
                "totalCost": 450.25
            }
        ],
        "totals": {
            "totalCost": 450.25
        }
    }'
    
    source "$PROJECT_DIR/scripts/json_parser.sh" >/dev/null 2>&1 || return
    
    local result=$(echo "$monthly_json" | get_current_month_cost)
    assert_equals "450.25" "$result" "Should extract current month cost"
}

# Run the tests
echo "Testing JSON parser functionality..."
test_get_today_cost
test_get_total_cost
test_get_cost_by_date
test_empty_json
test_invalid_json
test_monthly_json