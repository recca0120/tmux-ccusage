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
    
    # In test mode, use environment variables instead of tmux
    if [ -n "${TMUX_TEST_MODE:-}" ]; then
        local var_name="TMUX_OPT_${option//@/_}"
        var_name="${var_name//-/_}"
        eval "local option_value=\${${var_name}:-}"
        if [ -z "$option_value" ]; then
            echo "$default_value"
        else
            echo "$option_value"
        fi
        return
    fi
    
    local option_value=$(tmux show-option -gqv "$option" 2>/dev/null)
    
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

# Check if tmux-ccusage.sh exists in the parent directory (when in scripts/)
if [ -x "$SCRIPT_DIR/../tmux-ccusage.sh" ]; then
    # Call tmux-ccusage with specified format
    result="$("$SCRIPT_DIR/../tmux-ccusage.sh" "$display_format")"
    # Don't prepend "Claude" for custom format, let user control it
    if [ "$display_format" = "custom" ]; then
        echo "$result"
    else
        echo "Claude $result"
    fi
elif [ -x "$SCRIPT_DIR/tmux-ccusage.sh" ]; then
    # Check same directory (for compatibility)
    result="$("$SCRIPT_DIR/tmux-ccusage.sh" "$display_format")"
    if [ "$display_format" = "custom" ]; then
        echo "$result"
    else
        echo "Claude $result"
    fi
else
    # Fallback to check in standard tmux plugin path
    CCUSAGE_PATH="${HOME}/.tmux/plugins/tmux-ccusage/tmux-ccusage.sh"
    if [ -x "$CCUSAGE_PATH" ]; then
        result="$("$CCUSAGE_PATH" "$display_format")"
        if [ "$display_format" = "custom" ]; then
            echo "$result"
        else
            echo "Claude $result"
        fi
    else
        if [ "$display_format" = "custom" ]; then
            echo "\$0.00"
        else
            echo "Claude \$0.00"
        fi
    fi
fi