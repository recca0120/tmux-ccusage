#!/usr/bin/env bash

# tmux-ccusage - Display Claude usage in tmux status bar
# Main entry point script

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required modules
source "$SCRIPT_DIR/scripts/cache.sh"
source "$SCRIPT_DIR/scripts/json_parser.sh"
source "$SCRIPT_DIR/scripts/formatter.sh"

# Default settings
DEFAULT_FORMAT="daily_today"
DEFAULT_REPORT_TYPE="daily"

# Parse command line arguments
parse_args() {
    local format="${1:-$DEFAULT_FORMAT}"
    local report_type="${2:-$DEFAULT_REPORT_TYPE}"
    
    echo "$format|$report_type"
}

# Get tmux option value with default
get_tmux_option() {
    local option="$1"
    local default_value="$2"
    local option_value
    
    # In test mode, use environment variables instead of tmux
    if [ -n "${TMUX_TEST_MODE:-}" ]; then
        local var_name="TMUX_OPT_${option//@/_}"
        var_name="${var_name//-/_}"
        eval "option_value=\${${var_name}:-}"
        if [ -z "$option_value" ]; then
            echo "$default_value"
        else
            echo "$option_value"
        fi
        return
    fi
    
    # Check if tmux is available and we're in a tmux session
    if command -v tmux &> /dev/null && [ -n "${TMUX:-}" ]; then
        option_value=$(tmux show-option -gqv "$option" 2>/dev/null)
    fi
    
    if [ -z "$option_value" ]; then
        echo "$default_value"
    else
        echo "$option_value"
    fi
}

# Main function
main() {
    
    # Parse arguments
    local args
    args=$(parse_args "$@")
    local format="${args%|*}"
    local report_type="${args#*|}"
    
    # Get configuration from tmux options (use existing env vars as defaults)
    export CCUSAGE_REPORT_TYPE=${CCUSAGE_REPORT_TYPE:-$(get_tmux_option "@ccusage_report_type" "$report_type")}
    export CCUSAGE_SUBSCRIPTION_AMOUNT=${CCUSAGE_SUBSCRIPTION_AMOUNT:-$(get_tmux_option "@ccusage_subscription_amount" "0")}
    export CCUSAGE_SUBSCRIPTION_PLAN=${CCUSAGE_SUBSCRIPTION_PLAN:-$(get_tmux_option "@ccusage_subscription_plan" "")}
    export CCUSAGE_WARNING_THRESHOLD=${CCUSAGE_WARNING_THRESHOLD:-$(get_tmux_option "@ccusage_warning_threshold" "80")}
    export CCUSAGE_CRITICAL_THRESHOLD=${CCUSAGE_CRITICAL_THRESHOLD:-$(get_tmux_option "@ccusage_critical_threshold" "95")}
    export CCUSAGE_CUSTOM_FORMAT=${CCUSAGE_CUSTOM_FORMAT:-$(get_tmux_option "@ccusage_custom_format" "")}
    export CCUSAGE_CACHE_TTL=${CCUSAGE_CACHE_TTL:-$(get_tmux_option "@ccusage_cache_ttl" "30")}
    export CCUSAGE_SINCE=${CCUSAGE_SINCE:-$(get_tmux_option "@ccusage_since" "")}
    export CCUSAGE_UNTIL=${CCUSAGE_UNTIL:-$(get_tmux_option "@ccusage_until" "")}
    export CCUSAGE_DAYS=${CCUSAGE_DAYS:-$(get_tmux_option "@ccusage_days" "")}
    export CCUSAGE_MONTHS=${CCUSAGE_MONTHS:-$(get_tmux_option "@ccusage_months" "")}
    export CCUSAGE_MODE=${CCUSAGE_MODE:-$(get_tmux_option "@ccusage_mode" "auto")}
    export CCUSAGE_ORDER=${CCUSAGE_ORDER:-$(get_tmux_option "@ccusage_order" "asc")}
    export CCUSAGE_BREAKDOWN=${CCUSAGE_BREAKDOWN:-$(get_tmux_option "@ccusage_breakdown" "false")}
    export CCUSAGE_OFFLINE=${CCUSAGE_OFFLINE:-$(get_tmux_option "@ccusage_offline" "false")}
    
    # Handle subscription plan presets
    if [ -n "$CCUSAGE_SUBSCRIPTION_PLAN" ] && [ "$CCUSAGE_SUBSCRIPTION_AMOUNT" = "0" ]; then
        case "$CCUSAGE_SUBSCRIPTION_PLAN" in
            "free")
                CCUSAGE_SUBSCRIPTION_AMOUNT="0"
                ;;
            "pro")
                CCUSAGE_SUBSCRIPTION_AMOUNT="20"
                ;;
            "team")
                CCUSAGE_SUBSCRIPTION_AMOUNT="25"
                ;;
        esac
    fi
    
    # Build ccusage command arguments
    local ccusage_args=""
    
    # Add date filters
    if [ -n "$CCUSAGE_SINCE" ]; then
        ccusage_args="$ccusage_args --since $CCUSAGE_SINCE"
    fi
    if [ -n "$CCUSAGE_UNTIL" ]; then
        ccusage_args="$ccusage_args --until $CCUSAGE_UNTIL"
    fi
    if [ -n "$CCUSAGE_DAYS" ]; then
        ccusage_args="$ccusage_args --days $CCUSAGE_DAYS"
    fi
    if [ -n "$CCUSAGE_MONTHS" ]; then
        ccusage_args="$ccusage_args --months $CCUSAGE_MONTHS"
    fi
    
    # Add other options
    if [ "$CCUSAGE_MODE" != "auto" ]; then
        ccusage_args="$ccusage_args --mode $CCUSAGE_MODE"
    fi
    if [ "$CCUSAGE_ORDER" != "asc" ]; then
        ccusage_args="$ccusage_args --order $CCUSAGE_ORDER"
    fi
    if [ "$CCUSAGE_BREAKDOWN" = "true" ]; then
        ccusage_args="$ccusage_args --breakdown"
    fi
    if [ "$CCUSAGE_OFFLINE" = "true" ]; then
        ccusage_args="$ccusage_args --offline"
    fi
    
    # Get data from cache or fetch
    local json_data
    json_data=$(get_cached_or_fetch "$CCUSAGE_REPORT_TYPE" "$ccusage_args")
    
    # Check if we got valid data
    if [ -z "$json_data" ] || [ "$json_data" = "{}" ]; then
        echo "\$0.00"
        return
    fi
    
    # Format and display based on requested format
    case "$format" in
        "daily_today"|"today")
            echo "$json_data" | format_daily_today
            ;;
        "daily_total"|"total")
            echo "$json_data" | format_daily_total
            ;;
        "both")
            echo "$json_data" | format_both
            ;;
        "monthly_current"|"monthly")
            echo "$json_data" | format_monthly_current
            ;;
        "remaining")
            echo "$json_data" | format_remaining
            ;;
        "percentage")
            echo "$json_data" | format_percentage
            ;;
        "status")
            echo "$json_data" | format_status
            ;;
        "custom")
            echo "$json_data" | format_custom
            ;;
        *)
            # Default to daily_today
            echo "$json_data" | format_daily_today
            ;;
    esac
}

# Run main function
main "$@"