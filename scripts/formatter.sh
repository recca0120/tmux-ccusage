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

# Get currency symbol (default: $)
get_currency_symbol() {
    echo "${CCUSAGE_CURRENCY_SYMBOL:-\$}"
}

# Format daily today cost
format_daily_today() {
    local cost
    local currency
    cost=$(get_today_cost)
    currency=$(get_currency_symbol)
    echo "${currency}${cost}"
}

# Format daily total cost
format_daily_total() {
    local cost
    local currency
    cost=$(get_total_cost)
    currency=$(get_currency_symbol)
    echo "${currency}${cost}"
}

# Format both today and total
format_both() {
    local json_data
    json_data=$(cat)
    
    local today
    local total
    local currency
    today=$(echo "$json_data" | get_today_cost)
    total=$(echo "$json_data" | get_total_cost)
    currency=$(get_currency_symbol)
    echo "Today: ${currency}${today} | Total: ${currency}${total}"
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
    
    local currency
    currency=$(get_currency_symbol)
    echo "${currency}${remaining}/${currency}${subscription}"
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
    local currency
    currency=$(get_currency_symbol)
    local output="${currency}${total}"
    if [ "$subscription" != "0" ]; then
        output="$output/${currency}${subscription} (${percentage}%)"
    fi
    
    # Apply colors if enabled
    if [ "${CCUSAGE_ENABLE_COLORS:-true}" = "true" ] && [ -n "$TMUX" ]; then
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
    
    # Get currency symbol
    local currency
    currency=$(get_currency_symbol)
    
    # Replace currency placeholder first
    format="${format//\#\{currency\}/${currency}}"
    
    # Then replace other placeholders (with currency if not preceded by currency placeholder)
    # Check if the placeholder is preceded by the currency symbol to avoid double currency
    format="${format//\#\{daily\}/${currency}${daily}}"
    format="${format//\#\{total\}/${currency}${total}}"
    format="${format//\#\{today\}/${currency}${daily}}"
    
    # Handle cases where currency was explicitly used before placeholders
    format="${format//${currency}${currency}/${currency}}"
    
    echo "$format"
}

# Format monthly current cost
format_monthly_current() {
    local cost
    local currency
    cost=$(get_current_month_cost)
    currency=$(get_currency_symbol)
    echo "${currency}${cost}"
}