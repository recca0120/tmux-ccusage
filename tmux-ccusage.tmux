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

# Function to get tmux options with default
get_tmux_option() {
    local option=$1
    local default_value=$2
    local option_value=$(tmux show-option -gqv "$option" 2>/dev/null)
    
    if [ -z "$option_value" ]; then
        echo "$default_value"
    else
        echo "$option_value"
    fi
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

# Dracula theme integration functions
is_our_script() {
    local script_path=$1
    # Check for our marker
    grep -q "tmux-ccusage auto-generated" "$script_path" 2>/dev/null
}

install_dracula_script() {
    local source_script="$1"
    local target_script="$2"
    
    # Copy the script
    cp -f "$source_script" "$target_script"
    chmod +x "$target_script"
}

backup_existing_script() {
    local script_path=$1
    local backup_path="${script_path}.backup"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local timestamped_backup="${script_path}.backup.${timestamp}"
    
    # Create timestamped backup
    cp "$script_path" "$timestamped_backup"
    
    # Also create/update the simple backup
    cp "$script_path" "$backup_path"
}

# Dracula theme integration
handle_dracula_integration() {
    # Get configuration options
    local integrate_mode=$(get_tmux_option "@ccusage_dracula_auto_integrate" "true")
    local verbose=$(get_tmux_option "@ccusage_dracula_auto_integrate_verbose" "false")
    local backup=$(get_tmux_option "@ccusage_dracula_backup_custom" "true")
    
    # Check if Dracula theme is installed
    local dracula_dir="${HOME}/.tmux/plugins/tmux"
    if [ ! -d "$dracula_dir" ] || [ ! -f "$dracula_dir/dracula.tmux" ]; then
        [ "$verbose" = "true" ] && echo "tmux-ccusage: Dracula theme not found, skipping integration" >&2
        return 0
    fi
    
    # Handle different integration modes
    case "$integrate_mode" in
        "false"|"no"|"0")
            [ "$verbose" = "true" ] && echo "tmux-ccusage: Dracula auto-integration disabled" >&2
            return 0
            ;;
    esac
    
    # Create scripts directory if needed
    if [ ! -d "$dracula_dir/scripts" ]; then
        mkdir -p "$dracula_dir/scripts"
    fi
    
    local source_script="$CURRENT_DIR/scripts/dracula-ccusage.sh"
    local target_script="$dracula_dir/scripts/ccusage"
    
    # Check if source script exists
    if [ ! -f "$source_script" ]; then
        [ "$verbose" = "true" ] && echo "tmux-ccusage: Integration script not found" >&2
        return 1
    fi
    
    # Handle integration based on mode
    case "$integrate_mode" in
        "force")
            # Force mode: always install, backup if requested
            if [ -f "$target_script" ] && [ "$backup" = "true" ]; then
                backup_existing_script "$target_script"
                [ "$verbose" = "true" ] && echo "tmux-ccusage: Backed up existing script" >&2
            fi
            install_dracula_script "$source_script" "$target_script"
            [ "$verbose" = "true" ] && echo "tmux-ccusage: Force installed Dracula integration" >&2
            ;;
            
        "true"|"yes"|"1"|"smart"|*)
            # Smart mode (default): check before installing
            if [ -f "$target_script" ]; then
                if is_our_script "$target_script"; then
                    # It's our script, safe to update
                    install_dracula_script "$source_script" "$target_script"
                    [ "$verbose" = "true" ] && echo "tmux-ccusage: Updated Dracula integration" >&2
                else
                    # User's custom script, don't overwrite
                    [ "$verbose" = "true" ] && echo "tmux-ccusage: Custom ccusage script detected, skipping integration" >&2
                fi
            else
                # No existing script, safe to install
                install_dracula_script "$source_script" "$target_script"
                [ "$verbose" = "true" ] && echo "tmux-ccusage: Installed Dracula integration" >&2
            fi
            ;;
    esac
}

# Run Dracula integration
handle_dracula_integration