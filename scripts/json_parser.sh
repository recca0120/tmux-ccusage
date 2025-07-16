#!/usr/bin/env bash

# JSON parser functions for tmux-ccusage

# Get today's cost from ccusage JSON output
get_today_cost() {
    local json_data
    json_data=$(cat)
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        echo "0.00"
        return 1
    fi
    
    # Try to get the last daily entry (most recent date)
    local cost
    cost=$(echo "$json_data" | jq -r '.daily[-1].totalCost // 0' 2>/dev/null)
    
    # Format to 2 decimal places
    if [ "$cost" != "null" ] && [ -n "$cost" ] && [ "$cost" != "0" ]; then
        printf "%.2f" "$cost"
    else
        echo "0.00"
    fi
}

# Get total cost from ccusage JSON output
get_total_cost() {
    local json_data
    json_data=$(cat)
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        echo "0.00"
        return 1
    fi
    
    # Get total cost
    local cost
    cost=$(echo "$json_data" | jq -r '.totals.totalCost // 0' 2>/dev/null)
    
    # Format to 2 decimal places
    if [ "$cost" != "null" ] && [ -n "$cost" ] && [ "$cost" != "0" ]; then
        printf "%.2f" "$cost"
    else
        echo "0.00"
    fi
}

# Get cost by specific date
get_cost_by_date() {
    local date="$1"
    local json_data
    json_data=$(cat)
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        echo "0.00"
        return 1
    fi
    
    # Find cost for specific date
    local cost
    cost=$(echo "$json_data" | jq -r ".daily[] | select(.date == \"$date\") | .totalCost // 0" 2>/dev/null | head -1)
    
    # Format to 2 decimal places
    if [ "$cost" != "null" ] && [ -n "$cost" ] && [ "$cost" != "0" ]; then
        printf "%.2f" "$cost"
    else
        echo "0.00"
    fi
}

# Get current month cost
get_current_month_cost() {
    local json_data
    json_data=$(cat)
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        echo "0.00"
        return 1
    fi
    
    # Get current month in YYYY-MM format
    local current_month
    current_month=$(date +"%Y-%m")
    
    # Try to get monthly data
    local cost
    cost=$(echo "$json_data" | jq -r ".monthly[] | select(.month == \"$current_month\") | .totalCost // 0" 2>/dev/null | head -1)
    
    # If not found in monthly, try to sum daily entries for current month
    if [ -z "$cost" ] || [ "$cost" = "0" ] || [ "$cost" = "null" ]; then
        cost=$(echo "$json_data" | jq -r "[.daily[] | select(.date | startswith(\"$current_month\")) | .totalCost] | add // 0" 2>/dev/null)
    fi
    
    # Format to 2 decimal places
    if [ "$cost" != "null" ] && [ -n "$cost" ] && [ "$cost" != "0" ]; then
        printf "%.2f" "$cost"
    else
        echo "0.00"
    fi
}