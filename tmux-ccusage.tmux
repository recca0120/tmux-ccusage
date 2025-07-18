#!/usr/bin/env bash

# tmux-ccusage TPM plugin file

# This file should be run as a script when using TPM
# or sourced directly when testing

# Determine the directory containing this script
if [ -n "${BASH_SOURCE[0]}" ]; then
    CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
elif [ -n "$0" ] && [ "$0" != "bash" ] && [ "$0" != "sh" ]; then
    CURRENT_DIR="$( cd "$( dirname "$0" )" && pwd )"
else
    # Fallback: assume we're in the plugin directory
    CURRENT_DIR="$( pwd )"
fi

# Function to set tmux options
set_tmux_option() {
    local option=$1
    local value=$2
    tmux set-option -gq "$option" "$value"
}

# Set default format strings as user options
# These store the commands that can be used in status-line
set_tmux_option "@ccusage_daily_today" "#($CURRENT_DIR/tmux-ccusage.sh daily_today)"
set_tmux_option "@ccusage_daily_total" "#($CURRENT_DIR/tmux-ccusage.sh daily_total)"
set_tmux_option "@ccusage_both" "#($CURRENT_DIR/tmux-ccusage.sh both)"
set_tmux_option "@ccusage_monthly_current" "#($CURRENT_DIR/tmux-ccusage.sh monthly_current)"
set_tmux_option "@ccusage_remaining" "#($CURRENT_DIR/tmux-ccusage.sh remaining)"
set_tmux_option "@ccusage_percentage" "#($CURRENT_DIR/tmux-ccusage.sh percentage)"
set_tmux_option "@ccusage_status" "#($CURRENT_DIR/tmux-ccusage.sh status)"
set_tmux_option "@ccusage_custom" "#($CURRENT_DIR/tmux-ccusage.sh custom)"

# Convenience aliases
set_tmux_option "@ccusage_today" "#($CURRENT_DIR/tmux-ccusage.sh daily_today)"
set_tmux_option "@ccusage_total" "#($CURRENT_DIR/tmux-ccusage.sh daily_total)"
set_tmux_option "@ccusage_monthly" "#($CURRENT_DIR/tmux-ccusage.sh monthly_current)"

# Dracula theme integration
# Check if Dracula theme is installed (dracula/tmux installs to 'tmux' directory)
DRACULA_DIR="${HOME}/.tmux/plugins/tmux"
if [ -d "$DRACULA_DIR" ] && [ -f "$DRACULA_DIR/dracula.tmux" ]; then
    # Create scripts directory if it doesn't exist
    if [ ! -d "$DRACULA_DIR/scripts" ]; then
        mkdir -p "$DRACULA_DIR/scripts"
    fi
    
    # Copy dracula-ccusage.sh to Dracula's scripts directory as 'ccusage'
    if [ -f "$CURRENT_DIR/dracula-ccusage.sh" ]; then
        cp "$CURRENT_DIR/dracula-ccusage.sh" "$DRACULA_DIR/scripts/ccusage"
        chmod +x "$DRACULA_DIR/scripts/ccusage"
    fi
fi