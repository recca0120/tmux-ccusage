#!/usr/bin/env bats

# Test formatter functionality using Bats

setup() {
    # Load required scripts
    source "${BATS_TEST_DIRNAME}/../../scripts/json_parser.sh"
    source "${BATS_TEST_DIRNAME}/../../scripts/formatter.sh"
    
    # Mock JSON data
    export MOCK_JSON='{
      "daily": [
        {"date": "2025-07-15", "totalCost": 3.20},
        {"date": "2025-07-16", "totalCost": 130.45},
        {"date": "2025-07-17", "totalCost": 17.96}
      ],
      "totals": {"totalCost": 160.55}
    }'
}

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
    export CCUSAGE_SUBSCRIPTION_AMOUNT="200"
    result=$(echo "$MOCK_JSON" | format_remaining)
    [ "$result" = "\$39.45/\$200" ]
}

@test "format_percentage shows usage percentage" {
    export CCUSAGE_SUBSCRIPTION_AMOUNT="200"
    result=$(echo "$MOCK_JSON" | format_percentage)
    [ "$result" = "80.3%" ]
}

@test "format_percentage returns N/A when no subscription" {
    export CCUSAGE_SUBSCRIPTION_AMOUNT="0"
    result=$(echo "$MOCK_JSON" | format_percentage)
    [ "$result" = "N/A" ]
}

@test "format_status shows total with subscription info" {
    export CCUSAGE_SUBSCRIPTION_AMOUNT="200"
    export CCUSAGE_WARNING_THRESHOLD="80"
    export CCUSAGE_CRITICAL_THRESHOLD="95"
    
    result=$(echo "$MOCK_JSON" | format_status)
    [[ "$result" == *"160.55"* ]]
    [[ "$result" == *"200"* ]]
}

@test "format_custom uses custom template" {
    export CCUSAGE_CUSTOM_FORMAT='Daily: #{daily} / All: #{total}'
    result=$(echo "$MOCK_JSON" | format_custom)
    [ "$result" = "Daily: \$17.96 / All: \$160.55" ]
}

@test "format with empty JSON returns $0.00" {
    result=$(echo '{}' | format_daily_today)
    [ "$result" = "\$0.00" ]
}

@test "format_monthly_current shows monthly cost" {
    local monthly_json='{
        "monthly": [{"month": "2025-07", "totalCost": 450.25}]
    }'
    result=$(echo "$monthly_json" | format_monthly_current)
    [ "$result" = "\$450.25" ]
}