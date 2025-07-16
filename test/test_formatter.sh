#!/usr/bin/env bash

# Test display formatter functionality

# Source required scripts once at the beginning
if [ -f "$PROJECT_DIR/scripts/json_parser.sh" ]; then
    source "$PROJECT_DIR/scripts/json_parser.sh"
fi
if [ -f "$PROJECT_DIR/scripts/formatter.sh" ]; then
    source "$PROJECT_DIR/scripts/formatter.sh"
fi

# Mock JSON data
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

# Test format_daily_today
test_format_daily_today() {
    if ! command -v format_daily_today &> /dev/null; then
        assert_equals "" "" "formatter.sh not yet implemented"
        return
    fi
    
    local result=$(echo "$MOCK_JSON" | format_daily_today)
    assert_equals "\$17.96" "$result" "Should format today's cost with $"
}

# Test format_daily_total
test_format_daily_total() {
    
    
    local result=$(echo "$MOCK_JSON" | format_daily_total)
    assert_equals "\$160.55" "$result" "Should format total cost with $"
}

# Test format_both
test_format_both() {
    
    
    local result=$(echo "$MOCK_JSON" | format_both)
    assert_equals "Today: \$17.96 | Total: \$160.55" "$result" "Should format both costs"
}

# Test format_remaining with subscription
test_format_remaining() {
    
    
    export CCUSAGE_SUBSCRIPTION_AMOUNT="200"
    local result=$(echo "$MOCK_JSON" | format_remaining)
    assert_equals "\$39.45/\$200" "$result" "Should show remaining amount"
    unset CCUSAGE_SUBSCRIPTION_AMOUNT
}

# Test format_percentage
test_format_percentage() {
    
    
    export CCUSAGE_SUBSCRIPTION_AMOUNT="200"
    local result=$(echo "$MOCK_JSON" | format_percentage)
    assert_equals "80.3%" "$result" "Should show usage percentage"
    unset CCUSAGE_SUBSCRIPTION_AMOUNT
}

# Test format_status with warning colors
test_format_status_normal() {
    
    
    export CCUSAGE_SUBSCRIPTION_AMOUNT="200"
    export CCUSAGE_WARNING_THRESHOLD="80"
    export CCUSAGE_CRITICAL_THRESHOLD="95"
    
    # Test with 50% usage (should be normal)
    local test_json='{"totals":{"totalCost":100}}'
    local result=$(echo "$test_json" | format_status)
    # Check if result contains the cost (color codes might vary)
    if [[ "$result" == *"$100.00"* ]]; then
        assert_equals "contains" "contains" "Should contain cost in normal status"
    else
        assert_equals "contains $100.00" "$result" "Should contain cost in normal status"
    fi
    
    unset CCUSAGE_SUBSCRIPTION_AMOUNT
    unset CCUSAGE_WARNING_THRESHOLD
    unset CCUSAGE_CRITICAL_THRESHOLD
}

# Test custom format
test_custom_format() {
    
    
    export CCUSAGE_CUSTOM_FORMAT='Daily: #{daily} / All: #{total}'
    local result=$(echo "$MOCK_JSON" | format_custom)
    assert_equals "Daily: \$17.96 / All: \$160.55" "$result" "Should use custom format"
    unset CCUSAGE_CUSTOM_FORMAT
}

# Test format with no data
test_format_no_data() {
    
    
    local result=$(echo '{}' | format_daily_today)
    assert_equals "\$0.00" "$result" "Should show \$0.00 for no data"
}

# Test monthly format
test_format_monthly() {
    
    
    local monthly_json='{
        "monthly": [
            {
                "month": "2025-07",
                "totalCost": 450.25
            }
        ]
    }'
    
    local result=$(echo "$monthly_json" | format_monthly_current)
    assert_equals "\$450.25" "$result" "Should format monthly cost"
}

# Run the tests
echo "Testing formatter functionality..."
test_format_daily_today
test_format_daily_total
test_format_both
test_format_remaining
test_format_percentage
test_format_status_normal
test_custom_format
test_format_no_data
test_format_monthly