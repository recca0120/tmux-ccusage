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

@test "test_json_with_modelBreakdowns - Should extract correct totalCost ignoring modelBreakdowns" {
    # Test data with modelBreakdowns that contain cost fields
    local json_with_breakdowns='{
  "daily": [
    {
      "date": "2025-07-17",
      "inputTokens": 1000,
      "outputTokens": 2000,
      "totalTokens": 3000,
      "totalCost": 17.96,
      "modelBreakdowns": [
        {
          "modelName": "claude-3-opus",
          "inputTokens": 500,
          "outputTokens": 1000,
          "cost": 8.50
        },
        {
          "modelName": "claude-3-sonnet",
          "inputTokens": 500,
          "outputTokens": 1000,
          "cost": 9.46
        }
      ]
    },
    {
      "date": "2025-07-18",
      "inputTokens": 3000,
      "outputTokens": 114000,
      "totalTokens": 117000,
      "totalCost": 119.97,
      "modelBreakdowns": [
        {
          "modelName": "claude-opus-4",
          "inputTokens": 3000,
          "outputTokens": 114000,
          "cost": 119.97
        }
      ]
    }
  ],
  "totals": {"totalCost": 137.93}
}'
    
    # Should extract 119.97 (last daily entry totalCost), not the cost from modelBreakdowns
    result=$(echo "$json_with_breakdowns" | get_today_cost)
    [ "$result" = "119.97" ]
    
    # Test total cost extraction as well
    result_total=$(echo "$json_with_breakdowns" | get_total_cost)
    [ "$result_total" = "137.93" ]
}

@test "test_complex_modelBreakdowns - Should handle multiple entries with varying modelBreakdowns" {
    # Reproduce the issue where parser was returning 3.20 instead of correct value
    local complex_json='{
  "daily": [
    {
      "date": "2025-07-14",
      "totalCost": 8.94,
      "modelBreakdowns": [
        {"modelName": "claude-sonnet", "cost": 8.94}
      ]
    },
    {
      "date": "2025-07-15",
      "totalCost": 3.20,
      "modelBreakdowns": [
        {"modelName": "claude-sonnet", "cost": 3.20}
      ]
    },
    {
      "date": "2025-07-16",
      "totalCost": 130.45,
      "modelBreakdowns": [
        {"modelName": "claude-opus", "cost": 130.45}
      ]
    },
    {
      "date": "2025-07-18",
      "totalCost": 119.97,
      "modelBreakdowns": [
        {"modelName": "claude-opus-4", "cost": 119.97}
      ]
    }
  ],
  "totals": {"totalCost": 262.56}
}'
    
    # Should extract 119.97 (last entry), not 3.20 from earlier entry
    result=$(echo "$complex_json" | get_today_cost)
    [ "$result" = "119.97" ]
}

@test "test_monthly_with_modelBreakdowns - Should extract correct monthly totalCost" {
    # Test monthly data with modelBreakdowns
    local monthly_with_breakdowns='{
  "monthly": [
    {
      "month": "2025-06",
      "totalCost": 250.50,
      "modelBreakdowns": [
        {"modelName": "claude-3-opus", "cost": 150.25},
        {"modelName": "claude-3-sonnet", "cost": 100.25}
      ]
    },
    {
      "month": "2025-07",
      "totalCost": 511.67,
      "modelBreakdowns": [
        {"modelName": "claude-opus-4", "cost": 391.54},
        {"modelName": "claude-sonnet-4", "cost": 120.13}
      ]
    }
  ],
  "totals": {"totalCost": 762.17}
}'
    
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
    
    # Should extract 511.67, not costs from modelBreakdowns
    result=$(echo "$monthly_with_breakdowns" | get_current_month_cost)
    [ "$result" = "511.67" ]
    
    unset -f date
    unset MOCK_CURRENT_MONTH
}

