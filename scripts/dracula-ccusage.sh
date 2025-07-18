#!/usr/bin/env bash
# tmux-ccusage auto-generated
# Dracula theme plugin for tmux-ccusage
# This script outputs plain text without color codes
# Colors are handled by the Dracula theme itself

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find tmux-ccusage.sh
TMUX_CCUSAGE=""
for path in "$SCRIPT_DIR/../tmux-ccusage.sh" \
            "$SCRIPT_DIR/tmux-ccusage.sh" \
            "${HOME}/.tmux/plugins/tmux-ccusage/tmux-ccusage.sh"; do
    if [ -x "$path" ]; then
        TMUX_CCUSAGE="$path"
        break
    fi
done

# Simple get_tmux_option function (only what we need)
get_tmux_option() {
    local option=$1
    local default_value=$2
    
    if [ -n "${TMUX_TEST_MODE:-}" ]; then
        # Test mode - use environment variables
        local var_name="TMUX_OPT_${option//@/_}"
        var_name="${var_name//-/_}"
        if eval "[ -n \"\${${var_name}+x}\" ]"; then
            eval "echo \"\${${var_name}}\""
        else
            echo "$default_value"
        fi
    else
        # Production mode - use tmux
        local value=$(tmux show-option -gqv "$option" 2>/dev/null)
        echo "${value:-$default_value}"
    fi
}

# Get Dracula-specific options
display_format=$(get_tmux_option "@dracula-ccusage-display" "status")
dracula_prefix=$(get_tmux_option "@dracula-ccusage-prefix" "Claude ")
show_prefix=$(get_tmux_option "@dracula-ccusage-show-prefix" "true")

# Disable colors for Dracula theme
export CCUSAGE_ENABLE_COLORS="false"

# Set prefix if needed (except for custom format)
if [ "$display_format" != "custom" ] && [ "$show_prefix" = "true" ]; then
    export CCUSAGE_PREFIX="$dracula_prefix"
fi

# Execute tmux-ccusage.sh if found
if [ -n "$TMUX_CCUSAGE" ]; then
    exec "$TMUX_CCUSAGE" "$display_format"
fi

# Fallback output
if [ "$display_format" = "custom" ] || [ "$show_prefix" = "false" ]; then
    echo "\$0.00"
else
    echo "${dracula_prefix}\$0.00"
fi