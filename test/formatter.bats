#!/usr/bin/env bats

load test_helper

@test "format_daily_today shows today's cost with $" {
    result=$(echo "$MOCK_JSON" | format_daily_today)
    [ "$result" = "\$17.96" ]
}

@test "format_daily_total shows total cost with $" {
    result=$(echo "$MOCK_JSON" | format_daily_total)
    [ "$result" = "\$160.55" ]
}

@test "format_both shows both costs" {
    result=$(echo "$MOCK_JSON" | format_both)
    [ "$result" = "Today: \$17.96 | Total: \$160.55" ]
}

@test "format_remaining shows remaining amount" {
    export CCUSAGE_SUBSCRIPTION_AMOUNT=200
    result=$(echo "$MOCK_JSON" | format_remaining)
    [ "$result" = "\$39.45/\$200" ]
    unset CCUSAGE_SUBSCRIPTION_AMOUNT
}

@test "format_percentage shows usage percentage" {
    export CCUSAGE_SUBSCRIPTION_AMOUNT=200
    result=$(echo "$MOCK_JSON" | format_percentage)
    [ "$result" = "80.3%" ]
    unset CCUSAGE_SUBSCRIPTION_AMOUNT
}

@test "format_percentage returns N/A when no subscription" {
    export CCUSAGE_SUBSCRIPTION_AMOUNT=0
    result=$(echo "$MOCK_JSON" | format_percentage)
    [ "$result" = "N/A" ]
    unset CCUSAGE_SUBSCRIPTION_AMOUNT
}

@test "format_status shows total with subscription info" {
    export CCUSAGE_SUBSCRIPTION_AMOUNT=200
    export CCUSAGE_WARNING_THRESHOLD=80
    export CCUSAGE_CRITICAL_THRESHOLD=95
    
    result=$(echo '{"totals":{"totalCost":100}}' | format_status)
    [[ "$result" == *"100.00"* ]]
    [[ "$result" == *"200"* ]]
    [[ "$result" == *"50%"* ]]
    
    unset CCUSAGE_SUBSCRIPTION_AMOUNT
    unset CCUSAGE_WARNING_THRESHOLD
    unset CCUSAGE_CRITICAL_THRESHOLD
}

@test "format_custom uses custom template" {
    export CCUSAGE_CUSTOM_FORMAT='Daily: #{daily} / All: #{total}'
    result=$(echo "$MOCK_JSON" | format_custom)
    [ "$result" = "Daily: \$17.96 / All: \$160.55" ]
    unset CCUSAGE_CUSTOM_FORMAT
}

@test "format with empty JSON returns \$0.00" {
    result=$(echo "{}" | format_daily_today)
    [ "$result" = "\$0.00" ]
}

@test "format_monthly_current shows monthly cost" {
    # Mock the current month
    export MOCK_CURRENT_MONTH="2025-07"
    date() {
        if [ "$1" = "+%Y-%m" ]; then
            echo "$MOCK_CURRENT_MONTH"
        else
            command date "$@"
        fi
    }
    export -f date
    
    result=$(echo "$MOCK_MONTHLY_JSON" | format_monthly_current)
    [ "$result" = "\$450.25" ]
    
    unset -f date
    unset MOCK_CURRENT_MONTH
}