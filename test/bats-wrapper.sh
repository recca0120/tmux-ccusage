#!/usr/bin/env bash

# Wrapper script to run Bats tests with error suppression
# This script filters out annoying tput and broken pipe errors

# Set TERM if not set
if [ -z "${TERM:-}" ]; then
    export TERM=xterm
fi

# Run bats and filter stderr
exec 3>&1
bats "$@" 2>&1 1>&3 | grep -v "tput: No value" | grep -v "printf: write error: Broken pipe" 1>&2
exit ${PIPESTATUS[0]}