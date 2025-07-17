#!/usr/bin/env bash

# Wrapper script to run Bats tests with error suppression
# This script filters out annoying tput and broken pipe errors

# Set TERM if not set
if [ -z "${TERM:-}" ]; then
    export TERM=xterm-256color
fi

# Add fake tput to PATH
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$SCRIPT_DIR:$PATH"
ln -sf "$SCRIPT_DIR/fake-tput.sh" "$SCRIPT_DIR/tput" 2>/dev/null || true

# Create a temporary file for exit code
TMPFILE=$(mktemp)

# Run bats with all output captured and filtered
{
    bats "$@" 2>&1
    echo $? > "$TMPFILE"
} | grep -v "tput: No value" | grep -v "printf: write error: Broken pipe" | grep -v "validator.bash: line 8"

# Get the real exit code
EXIT_CODE=$(cat "$TMPFILE")
rm -f "$TMPFILE"

# Clean up fake tput
rm -f "$SCRIPT_DIR/tput"

exit $EXIT_CODE