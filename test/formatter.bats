#!/usr/bin/env bats

load test_helper

@test "test_format_daily_today - Should format today's cost with $" {
    result=$(echo "$MOCK_MULTI_DAY_JSON" | format_daily_today)
    [ "$result" = "\$17.96" ]
}

@test "test_format_daily_total - Should format total cost with $" {
    result=$(echo "$MOCK_MULTI_DAY_JSON" | format_daily_total)
    [ "$result" = "\$160.55" ]
}

@test "test_format_both - Should format both costs" {
    result=$(echo "$MOCK_MULTI_DAY_JSON" | format_both)
    [ "$result" = "Today: \$17.96 | Total: \$160.55" ]
}

@test "test_format_remaining - Should show remaining amount" {
    export CCUSAGE_SUBSCRIPTION_AMOUNT="200"
    result=$(echo "$MOCK_MULTI_DAY_JSON" | format_remaining)
    [ "$result" = "\$39.45/\$200" ]
    unset CCUSAGE_SUBSCRIPTION_AMOUNT
}

@test "test_format_percentage - Should show usage percentage" {
    export CCUSAGE_SUBSCRIPTION_AMOUNT="200"
    result=$(echo "$MOCK_MULTI_DAY_JSON" | format_percentage)
    [ "$result" = "80.3%" ]
    unset CCUSAGE_SUBSCRIPTION_AMOUNT
}

@test "test_format_status_normal - Should contain cost in normal status" {
    export CCUSAGE_SUBSCRIPTION_AMOUNT="200"
    export CCUSAGE_WARNING_THRESHOLD="80"
    export CCUSAGE_CRITICAL_THRESHOLD="95"
    
    # Test with 50% usage (should be normal)
    local test_json='{"totals":{"totalCost":100}}'
    result=$(echo "$test_json" | format_status)
    # Check if result contains the cost (color codes might vary)
    [[ "$result" == *"\$100.00"* ]]
    
    unset CCUSAGE_SUBSCRIPTION_AMOUNT
    unset CCUSAGE_WARNING_THRESHOLD
    unset CCUSAGE_CRITICAL_THRESHOLD
}

@test "test_custom_format - Should use custom format" {
    export CCUSAGE_CUSTOM_FORMAT='Daily: #{daily} / All: #{total}'
    result=$(echo "$MOCK_MULTI_DAY_JSON" | format_custom)
    [ "$result" = "Daily: \$17.96 / All: \$160.55" ]
    unset CCUSAGE_CUSTOM_FORMAT
}

@test "test_format_no_data - Should show \$0.00 for no data" {
    result=$(echo '{}' | format_daily_today)
    [ "$result" = "\$0.00" ]
}

@test "test_format_monthly - Should format monthly cost" {
    local monthly_json='{
        "monthly": [
            {
                "month": "2025-07",
                "totalCost": 450.25
            }
        ]
    }'
    
    result=$(echo "$monthly_json" | format_monthly_current)
    [ "$result" = "\$450.25" ]
}