#!/usr/bin/env bash
#
# Dracula theme wrapper for tmux-ccusage
# This script wraps tmux-ccusage for use as a Dracula custom plugin
#
# To use this with Dracula theme:
# 1. Copy this script to ~/.tmux/plugins/dracula/scripts/
# 2. Make it executable: chmod +x dracula-ccusage-wrapper.sh
# 3. Add to your tmux.conf: set -g @dracula-plugins "custom:dracula-ccusage-wrapper.sh"
# 4. Configure colors: set -g @dracula-custom-plugin-colors "orange dark_gray"

# Get the directory where tmux-ccusage is installed
# This assumes tmux-ccusage is installed via TPM in the standard location
TMUX_CCUSAGE_DIR="$HOME/.tmux/plugins/tmux-ccusage"

# Check if tmux-ccusage is installed
if [[ ! -f "$TMUX_CCUSAGE_DIR/tmux-ccusage.sh" ]]; then
    echo "tmux-ccusage not found!"
    exit 1
fi

# Source the get_tmux_option function if available
current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [[ -f "$current_dir/utils.sh" ]]; then
    source "$current_dir/utils.sh"
else
    # Fallback implementation of get_tmux_option
    get_tmux_option() {
        local option=$1
        local default_value=$2
        local option_value=$(tmux show-option -gqv "$option")
        if [[ -z "$option_value" ]]; then
            echo "$default_value"
        else
            echo "$option_value"
        fi
    }
fi

# Get configuration options
report_type=$(get_tmux_option "@ccusage_report_type" "daily")
display_format=$(get_tmux_option "@dracula_ccusage_format" "remaining")
show_icon=$(get_tmux_option "@dracula_ccusage_show_icon" "true")
icon=$(get_tmux_option "@dracula_ccusage_icon" "🤖")
label=$(get_tmux_option "@dracula_ccusage_label" "Claude")

# Get usage thresholds for color coding
warning_threshold=$(get_tmux_option "@ccusage_warning_threshold" "80")
critical_threshold=$(get_tmux_option "@ccusage_critical_threshold" "95")

# Execute tmux-ccusage based on display format
case "$display_format" in
    "remaining")
        output=$("$TMUX_CCUSAGE_DIR/tmux-ccusage.sh" remaining)
        ;;
    "percentage")
        output=$("$TMUX_CCUSAGE_DIR/tmux-ccusage.sh" percentage)
        # Extract percentage value for threshold checking
        percentage=$(echo "$output" | grep -o '[0-9]\+' | head -1)
        ;;
    "today")
        output=$("$TMUX_CCUSAGE_DIR/tmux-ccusage.sh" daily_today)
        ;;
    "status")
        output=$("$TMUX_CCUSAGE_DIR/tmux-ccusage.sh" status)
        ;;
    *)
        output=$("$TMUX_CCUSAGE_DIR/tmux-ccusage.sh")
        ;;
esac

# Format output with optional icon and label
if [[ "$show_icon" == "true" ]]; then
    if [[ -n "$label" ]]; then
        echo "${icon} ${label}: ${output}"
    else
        echo "${icon} ${output}"
    fi
else
    if [[ -n "$label" ]]; then
        echo "${label}: ${output}"
    else
        echo "${output}"
    fi
fi