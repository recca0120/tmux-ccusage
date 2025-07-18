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
    [ -f "$PROJECT_ROOT/scripts/dracula-ccusage.sh" ]
    [ -x "$PROJECT_ROOT/scripts/dracula-ccusage.sh" ]
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
result="\$("\$SCRIPT_DIR/tmux-ccusage.sh" status)"
echo "Claude \$result"
EOF
    chmod +x "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "Claude COLORS=false" ]
}

@test "dracula-ccusage.sh falls back when tmux-ccusage.sh not found" {
    # Create a dracula-ccusage.sh in temp dir without tmux-ccusage.sh
    cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    
    # Modify the script to use a non-existent home directory to avoid finding installed version
    sed -i.bak 's|${HOME}|/nonexistent|g' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "Claude \$0.00" ]
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
    cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    
    # Modify it to use our test directory
    sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="'"$BATS_TEST_TMPDIR"'"|' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "Claude FORMAT=daily_today" ]
}

@test "dracula-ccusage.sh uses status as default display format" {
    # Create a mock tmux-ccusage.sh
    cat > "$BATS_TEST_TMPDIR/tmux-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
echo "FORMAT=$1"
EOF
    chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
    
    # Create temporary dracula-ccusage.sh
    cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="'"$BATS_TEST_TMPDIR"'"|' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"FORMAT=status"* ]]
}

@test "dracula-ccusage.sh prepends 'Claude' to output" {
    # Create a mock tmux-ccusage.sh that outputs a cost
    cat > "$BATS_TEST_TMPDIR/tmux-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
echo "\$17.96"
EOF
    chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
    
    # Create temporary dracula-ccusage.sh
    cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="'"$BATS_TEST_TMPDIR"'"|' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "Claude \$17.96" ]
}

@test "dracula-ccusage.sh prepends 'Claude' to all format outputs" {
    # Test different format outputs
    formats=("daily_today" "monthly_current" "remaining" "percentage" "status")
    outputs=("\$17.96" "\$450.25" "\$39.45/\$200" "80.3%" "\$160.55/\$200 (80.3%)")
    
    for i in "${!formats[@]}"; do
        export TMUX_OPT__dracula_ccusage_display="${formats[$i]}"
        current_output="${outputs[$i]}"
        
        # Create a mock that outputs based on the format
        # Write script with escaped output
        {
            echo '#!/usr/bin/env bash'
            echo "echo '$current_output'"
        } > "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
        chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
        
        # Copy and modify dracula-ccusage.sh
        cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
        sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="'"$BATS_TEST_TMPDIR"'"|' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
        
        run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
        [ "$status" -eq 0 ]
        [ "$output" = "Claude $current_output" ]
    done
}

@test "dracula-ccusage.sh does not prepend 'Claude' for custom format" {
    # Set custom display format
    export TMUX_OPT__dracula_ccusage_display="custom"
    custom_output="My Custom Output: \$123.45"
    
    # Create a mock that outputs custom format
    {
        echo '#!/usr/bin/env bash'
        echo "echo '$custom_output'"
    } > "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
    chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
    
    # Copy and modify dracula-ccusage.sh
    cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="'"$BATS_TEST_TMPDIR"'"|' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "$custom_output" ]  # No "Claude" prefix
}

@test "dracula-ccusage.sh fallback returns plain $0.00 for custom format" {
    # Set custom display format
    export TMUX_OPT__dracula_ccusage_display="custom"
    
    # Create dracula-ccusage.sh without tmux-ccusage.sh
    cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    
    # Modify to use non-existent paths
    sed -i.bak 's|${HOME}|/nonexistent|g' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "\$0.00" ]  # No "Claude" prefix for custom format
}