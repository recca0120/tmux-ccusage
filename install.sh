#!/usr/bin/env bash

# Installation script for tmux-ccusage

set -e

INSTALL_DIR="${HOME}/.tmux/plugins/tmux-ccusage"

echo "Installing tmux-ccusage..."

# Check dependencies
echo "Checking dependencies..."

# Check for tmux
if ! command -v tmux &> /dev/null; then
    echo "Error: tmux is not installed"
    exit 1
fi

# Check tmux version (requires 2.1+)
TMUX_VERSION=$(tmux -V | cut -d' ' -f2)
REQUIRED_VERSION="2.1"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$TMUX_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "Error: tmux version $REQUIRED_VERSION or higher is required (found $TMUX_VERSION)"
    exit 1
fi

# Check for ccusage
if ! command -v ccusage &> /dev/null; then
    echo "Error: ccusage is not installed"
    echo "Please install ccusage first: npm install -g ccusage"
    exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed"
    echo "Please install jq:"
    echo "  macOS: brew install jq"
    echo "  Linux: sudo apt-get install jq"
    exit 1
fi

# Create plugin directory
echo "Creating plugin directory..."
mkdir -p "$INSTALL_DIR"

# Copy files
echo "Copying files..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy all necessary files
cp -r "$SCRIPT_DIR"/* "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/tmux-ccusage.sh"
chmod +x "$INSTALL_DIR/tmux-ccusage.tmux"
chmod +x "$INSTALL_DIR/scripts"/*.sh

# Check if TPM is installed
if [ -d "${HOME}/.tmux/plugins/tpm" ]; then
    echo ""
    echo "TPM detected. Add this line to your ~/.tmux.conf:"
    echo "  set -g @plugin 'recca0120/tmux-claude'"
    echo ""
    echo "Then press prefix + I to install the plugin."
else
    echo ""
    echo "Manual installation: Add this line to your ~/.tmux.conf:"
    echo "  run-shell $INSTALL_DIR/tmux-ccusage.tmux"
fi

echo ""
echo "Configuration example:"
echo "  set -g @ccusage_subscription_amount '200'"
echo "  set -g status-right 'Claude: #{ccusage_status} | %H:%M'"
echo ""
echo "For more options, see: $INSTALL_DIR/tmux-ccusage.conf"
echo ""
echo "Installation complete!"