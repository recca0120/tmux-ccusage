#!/usr/bin/env bash

# tmux-ccusage TPM plugin file

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set default format strings
tmux set-option -g @ccusage_daily_today "#($CURRENT_DIR/tmux-ccusage.sh daily_today)"
tmux set-option -g @ccusage_daily_total "#($CURRENT_DIR/tmux-ccusage.sh daily_total)"
tmux set-option -g @ccusage_both "#($CURRENT_DIR/tmux-ccusage.sh both)"
tmux set-option -g @ccusage_monthly_current "#($CURRENT_DIR/tmux-ccusage.sh monthly_current)"
tmux set-option -g @ccusage_remaining "#($CURRENT_DIR/tmux-ccusage.sh remaining)"
tmux set-option -g @ccusage_percentage "#($CURRENT_DIR/tmux-ccusage.sh percentage)"
tmux set-option -g @ccusage_status "#($CURRENT_DIR/tmux-ccusage.sh status)"
tmux set-option -g @ccusage_custom "#($CURRENT_DIR/tmux-ccusage.sh custom)"

# Convenience aliases
tmux set-option -g @ccusage_today "#($CURRENT_DIR/tmux-ccusage.sh daily_today)"
tmux set-option -g @ccusage_total "#($CURRENT_DIR/tmux-ccusage.sh daily_total)"
tmux set-option -g @ccusage_monthly "#($CURRENT_DIR/tmux-ccusage.sh monthly_current)"

# Set format strings that can be used in status-right/status-left
for format in daily_today daily_total both monthly_current remaining percentage status custom today total monthly; do
    tmux set-option -g "#{ccusage_${format}}" "#($CURRENT_DIR/tmux-ccusage.sh ${format})"
done