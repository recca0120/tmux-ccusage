#!/usr/bin/env bats

load test_helper

@test "get_today_cost returns today's cost" {
    result=$(echo "$MOCK_JSON" | get_today_cost)
    [ "$result" = "17.96" ]
}

@test "get_total_cost returns total cost" {
    result=$(echo "$MOCK_JSON" | get_total_cost)
    [ "$result" = "160.55" ]
}

@test "get_cost_by_date returns cost for specific date" {
    result=$(echo "$MOCK_JSON" | get_cost_by_date "2025-07-17")
    [ "$result" = "17.96" ]
}

@test "empty JSON returns 0.00" {
    result=$(echo "{}" | get_today_cost)
    [ "$result" = "0.00" ]
}

@test "invalid JSON returns 0.00" {
    result=$(echo "invalid" | get_today_cost)
    [ "$result" = "0.00" ]
}

@test "get_current_month_cost with monthly data" {
    # Mock the current month
    export MOCK_CURRENT_MONTH="2025-07"
    
    # Override the date command for testing
    date() {
        if [ "$1" = "+%Y-%m" ]; then
            echo "$MOCK_CURRENT_MONTH"
        else
            command date "$@"
        fi
    }
    export -f date
    
    result=$(echo "$MOCK_MONTHLY_JSON" | get_current_month_cost)
    [ "$result" = "450.25" ]
    
    unset -f date
    unset MOCK_CURRENT_MONTH
}

@test "extract_last_daily_cost with multiple days" {
    result=$(echo "$MOCK_MULTI_DAY_JSON" | extract_last_daily_cost)
    [ "$result" = "17.96" ]
}

@test "normalize_json handles compact JSON" {
    compact='{"key":"value","nested":{"item":123}}'
    result=$(echo "$compact" | normalize_json | grep -c "^{$")
    [ "$result" -ge 1 ]
}