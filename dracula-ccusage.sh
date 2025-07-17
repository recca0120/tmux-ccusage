#!/usr/bin/env bash
# Dracula theme plugin for tmux-ccusage
# This script outputs plain text without color codes
# Colors are handled by the Dracula theme itself

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to get tmux option with default value
get_tmux_option() {
    local option=$1
    local default_value=$2
    local option_value=$(tmux show-option -gqv "$option")
    
    if [ -z "$option_value" ]; then
        echo "$default_value"
    else
        echo "$option_value"
    fi
}

# Get display format from tmux option
display_format=$(get_tmux_option "@dracula-ccusage-display" "status")

# Disable colors when called from Dracula theme
export CCUSAGE_ENABLE_COLORS="false"

# Check if tmux-ccusage.sh exists in the same directory
if [ -x "$SCRIPT_DIR/tmux-ccusage.sh" ]; then
    # Call tmux-ccusage with specified format
    "$SCRIPT_DIR/tmux-ccusage.sh" "$display_format"
else
    # Fallback to check in standard tmux plugin path
    CCUSAGE_PATH="${HOME}/.tmux/plugins/tmux-ccusage/tmux-ccusage.sh"
    if [ -x "$CCUSAGE_PATH" ]; then
        "$CCUSAGE_PATH" "$display_format"
    else
        echo "$0.00"
    fi
fi