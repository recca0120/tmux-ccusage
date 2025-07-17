#!/usr/bin/env bats

# Test JSON parser functionality using Bats

setup() {
    # Load the script
    source "${BATS_TEST_DIRNAME}/../../scripts/json_parser.sh"
    
    # Mock JSON data
    export MOCK_JSON='{
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
}

@test "get_today_cost returns today's cost" {
    result=$(echo "$MOCK_JSON" | get_today_cost)
    [ "$result" = "17.96" ]
}

@test "get_total_cost returns total cost" {
    result=$(echo "$MOCK_JSON" | get_total_cost)
    [ "$result" = "160.55" ]
}

@test "get_cost_by_date returns cost for specific date" {
    result=$(echo "$MOCK_JSON" | get_cost_by_date "2025-07-16")
    [ "$result" = "130.45" ]
}

@test "empty JSON returns 0.00" {
    result=$(echo '{}' | get_today_cost)
    [ "$result" = "0.00" ]
}

@test "invalid JSON returns 0.00" {
    result=$(echo 'invalid json' | get_today_cost)
    [ "$result" = "0.00" ]
}

@test "get_current_month_cost with monthly data" {
    local monthly_json='{
        "monthly": [
            {
                "month": "2025-07",
                "totalCost": 450.25
            }
        ]
    }'
    
    result=$(echo "$monthly_json" | get_current_month_cost)
    [ "$result" = "450.25" ]
}