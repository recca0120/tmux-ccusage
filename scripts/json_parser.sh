#!/usr/bin/env bash

# JSON parser functions for tmux-ccusage

# Pure shell JSON parser for simple extraction
# This handles both pretty-printed and compact JSON formats

# Normalize JSON to make it easier to parse
normalize_json() {
    # Add newlines after common JSON elements to handle compact format
    sed 's/,/,\n/g; s/{/{\n/g; s/}/\n}/g; s/\[/\[\n/g; s/\]/\n\]/g'
}

# Extract last daily entry's totalCost
extract_last_daily_cost() {
    local json_data
    json_data=$(cat | normalize_json)
    
    # Find all totalCost values in daily entries and get the last one
    local costs
    costs=$(echo "$json_data" | grep -A 100 '"daily"' | grep -B 100 ']' | grep '"totalCost"' | sed 's/.*"totalCost":[[:space:]]*\([0-9.]*\).*/\1/')
    
    # Count how many costs we found
    local count
    count=$(echo "$costs" | wc -l)
    
    # In the real data, modelBreakdowns also has cost fields
    # The pattern is: for each daily entry, there's one totalCost followed by costs in modelBreakdowns
    # So we need to skip the modelBreakdowns costs
    
    # Get all the costs and filter out the ones from modelBreakdowns
    # Simple heuristic: daily entry totalCosts are usually at positions 1, n+1, 2n+1, etc.
    # where n is the number of models in modelBreakdowns
    
    # For now, let's use a different approach: 
    # Count dates to know how many daily entries we have
    local date_count
    date_count=$(echo "$json_data" | grep -A 100 '"daily"' | grep -B 100 ']' | grep -c '"date"')
    
    if [ "$date_count" -gt 0 ]; then
        # Get the totalCost at position that corresponds to the last date
        # This is a workaround - we're getting the date_count-th totalCost
        local last_cost
        last_cost=$(echo "$costs" | sed -n "${date_count}p")
        
        if [ -n "$last_cost" ]; then
            echo "$last_cost"
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}

# Extract total cost from totals object
extract_total_cost() {
    local json_data
    json_data=$(cat | normalize_json)
    
    # Find totalCost in totals section
    local cost
    cost=$(echo "$json_data" | grep -A 10 '"totals"' | grep '"totalCost"' | head -1 | sed 's/.*"totalCost":[[:space:]]*\([0-9.]*\).*/\1/')
    
    if [ -n "$cost" ]; then
        echo "$cost"
    else
        echo "0"
    fi
}

# Extract cost by specific date
extract_cost_by_date() {
    local target_date="$1"
    local json_data
    json_data=$(cat | normalize_json)
    
    # Find the date and then look for totalCost in the same object
    local cost
    cost=$(echo "$json_data" | grep -A 20 "\"date\":[[:space:]]*\"$target_date\"" | grep '"totalCost"' | head -1 | sed 's/.*"totalCost":[[:space:]]*\([0-9.]*\).*/\1/')
    
    if [ -n "$cost" ]; then
        echo "$cost"
    else
        echo "0"
    fi
}

# Extract current month cost
extract_current_month_cost() {
    local json_data
    json_data=$(cat | normalize_json)
    
    local current_month
    current_month=$(date +"%Y-%m")
    
    # First try to find in monthly array
    local monthly_cost
    monthly_cost=$(echo "$json_data" | grep -A 20 "\"month\":[[:space:]]*\"$current_month\"" | grep '"totalCost"' | head -1 | sed 's/.*"totalCost":[[:space:]]*\([0-9.]*\).*/\1/')
    
    if [ -n "$monthly_cost" ]; then
        echo "$monthly_cost"
        return 0
    fi
    
    # If not found in monthly, sum daily entries for current month
    local daily_costs
    daily_costs=$(echo "$json_data" | awk -v month="$current_month" '
        /"date":[[:space:]]*"/ {
            gsub(/.*"date":[[:space:]]*"/, "")
            gsub(/".*/, "")
            date = $0
            if (substr(date, 1, 7) == month) {
                in_month = 1
            } else {
                in_month = 0
            }
        }
        in_month && /"totalCost":/ {
            gsub(/.*"totalCost":[[:space:]]*/, "")
            gsub(/[,}].*/, "")
            sum += $0
        }
        END {
            print sum > 0 ? sum : "0"
        }
    ')
    
    echo "$daily_costs"
}

# Get today's cost from ccusage JSON output
get_today_cost() {
    local json_data
    json_data=$(cat)
    
    # Use pure shell parser
    local cost
    cost=$(echo "$json_data" | extract_last_daily_cost)
    
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
    
    # Use pure shell parser
    local cost
    cost=$(echo "$json_data" | extract_total_cost)
    
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
    
    # Use pure shell parser
    local cost
    cost=$(echo "$json_data" | extract_cost_by_date "$date")
    
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
    
    # Use pure shell parser
    local cost
    cost=$(echo "$json_data" | extract_current_month_cost)
    
    # Format to 2 decimal places
    if [ "$cost" != "null" ] && [ -n "$cost" ] && [ "$cost" != "0" ]; then
        printf "%.2f" "$cost"
    else
        echo "0.00"
    fi
}