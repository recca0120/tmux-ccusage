#!/usr/bin/env bats

# Test for Dracula theme integration

setup() {
    # Set test mode
    export TMUX_TEST_MODE=1
    export DEBUG_TMUX_CCUSAGE=1
    
    # Get the directory containing this test file
    TEST_DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    PROJECT_ROOT="$(dirname "$TEST_DIR")"
    
    # Source the dracula wrapper script
    export PATH="$PROJECT_ROOT:$PATH"
    
    # Create test cache directory
    export CCUSAGE_CACHE_DIR="$BATS_TEST_TMPDIR/cache"
    mkdir -p "$CCUSAGE_CACHE_DIR"
}

teardown() {
    # Clean up
    rm -rf "$BATS_TEST_TMPDIR/cache"
    unset TMUX_TEST_MODE
    unset DEBUG_TMUX_CCUSAGE
    unset CCUSAGE_ENABLE_COLORS
    unset CCUSAGE_CACHE_DIR
}

@test "dracula-ccusage.sh exists and is executable" {
    [ -f "$PROJECT_ROOT/dracula-ccusage.sh" ]
    [ -x "$PROJECT_ROOT/dracula-ccusage.sh" ]
}

@test "dracula-ccusage.sh disables colors" {
    # Create a mock tmux-ccusage.sh that outputs the CCUSAGE_ENABLE_COLORS value
    cat > "$BATS_TEST_TMPDIR/tmux-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
echo "COLORS=${CCUSAGE_ENABLE_COLORS}"
EOF
    chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
    
    # Create a temporary dracula-ccusage.sh that uses our mock
    cat > "$BATS_TEST_TMPDIR/dracula-ccusage.sh" << EOF
#!/usr/bin/env bash
SCRIPT_DIR="$BATS_TEST_TMPDIR"
export CCUSAGE_ENABLE_COLORS="false"
"\$SCRIPT_DIR/tmux-ccusage.sh" status
EOF
    chmod +x "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "COLORS=false" ]
}

@test "dracula-ccusage.sh falls back when tmux-ccusage.sh not found" {
    # Create a dracula-ccusage.sh in temp dir without tmux-ccusage.sh
    cp "$PROJECT_ROOT/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "$0.00" ]
}

@test "dracula-ccusage.sh supports custom display format" {
    # Set tmux option for display format
    export TMUX_OPT__dracula_ccusage_display="daily_today"
    
    # Create a mock tmux-ccusage.sh that outputs the format it received
    cat > "$BATS_TEST_TMPDIR/tmux-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
echo "FORMAT=$1"
EOF
    chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
    
    # Create a temporary dracula-ccusage.sh
    cp "$PROJECT_ROOT/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    
    # Modify it to use our test directory
    sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="'"$BATS_TEST_TMPDIR"'"|' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "FORMAT=daily_today" ]
}

@test "dracula-ccusage.sh uses status as default display format" {
    # Create a mock tmux-ccusage.sh
    cat > "$BATS_TEST_TMPDIR/tmux-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
echo "FORMAT=$1"
EOF
    chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
    
    # Create temporary dracula-ccusage.sh
    cp "$PROJECT_ROOT/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="'"$BATS_TEST_TMPDIR"'"|' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "FORMAT=status" ]
}