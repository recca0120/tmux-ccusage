#!/usr/bin/env bash

# Display formatter for tmux-ccusage

# Source JSON parser
if [ -n "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# Only source if not already loaded
if ! command -v get_today_cost &> /dev/null; then
    # shellcheck source=scripts/json_parser.sh
    source "$SCRIPT_DIR/json_parser.sh"
fi

# Format daily today cost
format_daily_today() {
    local cost
    cost=$(get_today_cost)
    echo "\$$cost"
}

# Format daily total cost
format_daily_total() {
    local cost
    cost=$(get_total_cost)
    echo "\$$cost"
}

# Format both today and total
format_both() {
    local json_data
    json_data=$(cat)
    
    local today
    local total
    today=$(echo "$json_data" | get_today_cost)
    total=$(echo "$json_data" | get_total_cost)
    echo "Today: \$$today | Total: \$$total"
}

# Format remaining quota
format_remaining() {
    local json_data
    json_data=$(cat)
    
    local total
    local subscription="${CCUSAGE_SUBSCRIPTION_AMOUNT:-0}"
    
    total=$(echo "$json_data" | get_total_cost)
    
    # Calculate remaining
    local remaining
    remaining=$(awk -v s="$subscription" -v t="$total" 'BEGIN {printf "%.2f", s - t}')
    
    # Ensure no negative values
    if (( $(echo "$remaining < 0" | bc -l) )); then
        remaining="0.00"
    fi
    
    echo "\$$remaining/\$$subscription"
}

# Format usage percentage
format_percentage() {
    local json_data
    json_data=$(cat)
    
    local total
    local subscription="${CCUSAGE_SUBSCRIPTION_AMOUNT:-0}"
    
    total=$(echo "$json_data" | get_total_cost)
    
    if [ "$subscription" = "0" ]; then
        echo "N/A"
        return
    fi
    
    # Calculate percentage
    local percentage
    percentage=$(awk -v s="$subscription" -v t="$total" 'BEGIN {printf "%.1f", (t / s) * 100}')
    
    echo "${percentage}%"
}

# Format status with color coding
format_status() {
    local json_data
    json_data=$(cat)
    
    local total
    local subscription="${CCUSAGE_SUBSCRIPTION_AMOUNT:-0}"
    local warning_threshold="${CCUSAGE_WARNING_THRESHOLD:-80}"
    local critical_threshold="${CCUSAGE_CRITICAL_THRESHOLD:-95}"
    
    total=$(echo "$json_data" | get_total_cost)
    
    # Calculate percentage if subscription is set
    local percentage=0
    if [ "$subscription" != "0" ]; then
        percentage=$(awk -v s="$subscription" -v t="$total" 'BEGIN {printf "%.0f", (t / s) * 100}')
    fi
    
    # Determine color based on thresholds
    local color=""
    if [ "$percentage" -ge "$critical_threshold" ]; then
        color="#[fg=red]"
    elif [ "$percentage" -ge "$warning_threshold" ]; then
        color="#[fg=yellow]"
    else
        color="#[fg=green]"
    fi
    
    # Format output
    local output="\$$total"
    if [ "$subscription" != "0" ]; then
        output="$output/\$$subscription (${percentage}%)"
    fi
    
    # Return with color if in tmux
    if [ -n "$TMUX" ]; then
        echo "${color}${output}#[default]"
    else
        echo "$output"
    fi
}

# Format with custom template
format_custom() {
    local json_data
    json_data=$(cat)
    
    local format="${CCUSAGE_CUSTOM_FORMAT:-'Daily: #{daily} / All: #{total}'}"
    local daily
    local total
    
    daily=$(echo "$json_data" | get_today_cost)
    total=$(echo "$json_data" | get_total_cost)
    
    # Replace placeholders
    format="${format//\#\{daily\}/\$$daily}"
    format="${format//\#\{total\}/\$$total}"
    format="${format//\#\{today\}/\$$daily}"
    
    echo "$format"
}

# Format monthly current cost
format_monthly_current() {
    local cost
    cost=$(get_current_month_cost)
    echo "\$$cost"
}