#!/usr/bin/env bats

load test_helper

@test "test_get_today_cost - Should extract today's cost (17.96)" {
    # 使用與 commit 33e43763 相同的多日 JSON 資料
    result=$(echo "$MOCK_MULTI_DAY_JSON" | get_today_cost)
    [ "$result" = "17.96" ]
}

@test "test_get_total_cost - Should extract total cost (160.55)" {
    # 使用與 commit 33e43763 相同的多日 JSON 資料
    result=$(echo "$MOCK_MULTI_DAY_JSON" | get_total_cost)
    [ "$result" = "160.55" ]
}

@test "test_get_cost_by_date - Should extract cost for specific date" {
    # 使用與 commit 33e43763 相同的測試：提取 2025-07-16 的 130.45
    result=$(echo "$MOCK_MULTI_DAY_JSON" | get_cost_by_date "2025-07-16")
    [ "$result" = "130.45" ]
}

@test "test_empty_json - Should return 0.00 for empty JSON" {
    result=$(echo "{}" | get_today_cost)
    [ "$result" = "0.00" ]
}

@test "test_invalid_json - Should return 0.00 for invalid JSON" {
    result=$(echo "invalid json" | get_today_cost)
    [ "$result" = "0.00" ]
}

@test "test_monthly_json - Should extract current month cost" {
    # Use multi-month data from MOCK_MONTHLY_JSON
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
    
    result=$(echo "$MOCK_MONTHLY_JSON" | get_current_month_cost)
    [ "$result" = "450.25" ]
    
    unset -f date
    unset MOCK_CURRENT_MONTH
}

