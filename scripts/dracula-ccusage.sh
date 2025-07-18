#!/usr/bin/env bash
# Dracula theme integration script for tmux-ccusage
# This script outputs a single line for display in Dracula theme status bar

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# Set TMUX environment variable to enable tmux functions
export TMUX="${TMUX:-dummy}"

# Load the tmux-ccusage functions by executing in a subshell
get_ccusage_value() {
    "$PLUGIN_DIR/tmux-ccusage.sh" "$1"
}

# Get tmux option helper function
get_tmux_option() {
    local option=$1
    local default_value=$2
    if [ -n "$TMUX" ] && [ "$TMUX" != "dummy" ]; then
        local option_value=$(tmux show-option -gqv "$option")
        if [ -n "$option_value" ]; then
            echo "$option_value"
        else
            echo "$default_value"
        fi
    else
        echo "$default_value"
    fi
}

# Get configuration from tmux (with defaults)
display_format=$(get_tmux_option "@ccusage_dracula_format" "status")
show_icon=$(get_tmux_option "@ccusage_dracula_show_icon" "true")
icon=$(get_tmux_option "@ccusage_dracula_icon" "💰")

# Get the ccusage value based on format
case "$display_format" in
    "daily_today")
        value=$(get_ccusage_value "daily_today")
        ;;
    "daily_total")
        value=$(get_ccusage_value "daily_total")
        ;;
    "monthly_current")
        value=$(get_ccusage_value "monthly_current")
        ;;
    "monthly_total")
        value=$(get_ccusage_value "monthly_total")
        ;;
    "remaining")
        value=$(get_ccusage_value "remaining")
        ;;
    "percentage")
        value=$(get_ccusage_value "percentage")
        ;;
    "status"|*)
        value=$(get_ccusage_value "status")
        ;;
esac

# Output with or without icon
if [ "$show_icon" = "true" ]; then
    echo "$icon $value"
else
    echo "$value"
fi