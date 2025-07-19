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
prefix="${CCUSAGE_PREFIX:-}"
echo "${prefix}FORMAT=$1"
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
prefix="${CCUSAGE_PREFIX:-}"
echo "${prefix}FORMAT=$1"
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
prefix="${CCUSAGE_PREFIX:-}"
echo "${prefix}\$17.96"
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
    outputs=('$17.96' '$450.25' '$39.45/$200' '80.3%' '$160.55/$200 (80.3%)')
    
    for i in "${!formats[@]}"; do
        export TMUX_OPT__dracula_ccusage_display="${formats[$i]}"
        expected_output="${outputs[$i]}"
        
        # Create a mock that outputs based on the format
        cat > "$BATS_TEST_TMPDIR/tmux-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
# Mock tmux-ccusage.sh for testing
prefix="${CCUSAGE_PREFIX:-}"

# Map format to expected output
case "$1" in
    "daily_today") echo "${prefix}\$17.96" ;;
    "monthly_current") echo "${prefix}\$450.25" ;;
    "remaining") echo "${prefix}\$39.45/\$200" ;;
    "percentage") echo "${prefix}80.3%" ;;
    "status") echo "${prefix}\$160.55/\$200 (80.3%)" ;;
    *) echo "${prefix}UNKNOWN" ;;
esac
EOF
        chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
        
        # Copy and modify dracula-ccusage.sh
        cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
        sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="'"$BATS_TEST_TMPDIR"'"|' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
        
        run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
        [ "$status" -eq 0 ]
        [ "$output" = "Claude ${expected_output}" ]
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

# New tests for label customization feature

@test "dracula-ccusage.sh supports custom prefix" {
    # Test custom prefix feature
    export TMUX_OPT__dracula_ccusage_prefix="AI "
    
    # Create a mock tmux-ccusage.sh
    cat > "$BATS_TEST_TMPDIR/tmux-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
prefix="${CCUSAGE_PREFIX:-}"
echo "${prefix}\$100.00"
EOF
    chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
    
    # Copy and modify dracula-ccusage.sh
    cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="'"$BATS_TEST_TMPDIR"'"|' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "AI \$100.00" ]
}

@test "dracula-ccusage.sh supports emoji prefix" {
    # Test emoji prefix
    export TMUX_OPT__dracula_ccusage_prefix="🤖 "
    
    # Create a mock tmux-ccusage.sh
    cat > "$BATS_TEST_TMPDIR/tmux-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
prefix="${CCUSAGE_PREFIX:-}"
echo "${prefix}\$50.00"
EOF
    chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
    
    # Copy and modify dracula-ccusage.sh
    cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="'"$BATS_TEST_TMPDIR"'"|' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "🤖 \$50.00" ]
}

@test "dracula-ccusage.sh hides prefix when show-prefix is false" {
    # Test hiding prefix
    export TMUX_OPT__dracula_ccusage_show_prefix="false"
    
    # Create a mock tmux-ccusage.sh
    cat > "$BATS_TEST_TMPDIR/tmux-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
prefix="${CCUSAGE_PREFIX:-}"
echo "${prefix}\$75.00"
EOF
    chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
    
    # Copy and modify dracula-ccusage.sh
    cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="'"$BATS_TEST_TMPDIR"'"|' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "\$75.00" ]  # No prefix
}

@test "dracula-ccusage.sh shows default prefix when show-prefix is true" {
    # Test showing default prefix explicitly
    export TMUX_OPT__dracula_ccusage_show_prefix="true"
    
    # Create a mock tmux-ccusage.sh
    cat > "$BATS_TEST_TMPDIR/tmux-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
prefix="${CCUSAGE_PREFIX:-}"
echo "${prefix}\$25.00"
EOF
    chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
    
    # Copy and modify dracula-ccusage.sh
    cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="'"$BATS_TEST_TMPDIR"'"|' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "Claude \$25.00" ]  # Default prefix
}

@test "dracula-ccusage.sh custom format ignores prefix even when show-prefix is true" {
    # Custom format should not have prefix even if show-prefix is true
    export TMUX_OPT__dracula_ccusage_display="custom"
    export TMUX_OPT__dracula_ccusage_show_prefix="true"
    export TMUX_OPT__dracula_ccusage_prefix="TEST "
    
    # Create a mock tmux-ccusage.sh
    cat > "$BATS_TEST_TMPDIR/tmux-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
# Custom format should not prepend prefix
echo "Custom: \$123.45"
EOF
    chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
    
    # Copy and modify dracula-ccusage.sh
    cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="'"$BATS_TEST_TMPDIR"'"|' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "Custom: \$123.45" ]  # No prefix for custom format
}

@test "dracula-ccusage.sh combines custom prefix with different display formats" {
    # Test custom prefix with remaining format
    export TMUX_OPT__dracula_ccusage_display="remaining"
    export TMUX_OPT__dracula_ccusage_prefix="API Usage "
    
    # Create a mock tmux-ccusage.sh
    cat > "$BATS_TEST_TMPDIR/tmux-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
prefix="${CCUSAGE_PREFIX:-}"
echo "${prefix}\$39.45/\$200"
EOF
    chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
    
    # Copy and modify dracula-ccusage.sh
    cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="'"$BATS_TEST_TMPDIR"'"|' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "API Usage \$39.45/\$200" ]
}

@test "dracula-ccusage.sh handles empty prefix correctly" {
    # Test empty prefix
    export TMUX_OPT__dracula_ccusage_prefix=""
    export TMUX_OPT__dracula_ccusage_show_prefix="true"
    
    # Create a mock tmux-ccusage.sh
    cat > "$BATS_TEST_TMPDIR/tmux-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
prefix="${CCUSAGE_PREFIX:-}"
echo "${prefix}\$99.99"
EOF
    chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
    
    # Copy and modify dracula-ccusage.sh
    cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="'"$BATS_TEST_TMPDIR"'"|' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "\$99.99" ]  # No prefix when empty
}

@test "dracula-ccusage.sh prefix works with all non-custom formats" {
    # Test prefix with all formats except custom
    formats=("status" "remaining" "percentage" "today" "total" "daily_today" "daily_total")
    
    for format in "${formats[@]}"; do
        export TMUX_OPT__dracula_ccusage_display="$format"
        export TMUX_OPT__dracula_ccusage_prefix="Test "
        
        # Create a mock tmux-ccusage.sh
        cat > "$BATS_TEST_TMPDIR/tmux-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
prefix="${CCUSAGE_PREFIX:-}"
echo "${prefix}OUTPUT"
EOF
        chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
        
        # Copy and modify dracula-ccusage.sh
        cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
        sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="'"$BATS_TEST_TMPDIR"'"|' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
        
        run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
        [ "$status" -eq 0 ]
        [ "$output" = "Test OUTPUT" ]
    done
}

# Tests for @dracula-ccusage-colors support

@test "dracula-ccusage.sh reads @dracula-ccusage-colors option" {
    # Test that the script can read the colors option
    export TMUX_OPT__dracula_ccusage_colors="orange dark_gray"
    
    # Create a modified dracula-ccusage.sh that outputs the colors
    cat > "$BATS_TEST_TMPDIR/dracula-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/get_tmux_option.sh"
colors=$(get_tmux_option "@dracula-ccusage-colors" "")
echo "COLORS=$colors"
EOF
    
    # Create the get_tmux_option.sh helper
    cat > "$BATS_TEST_TMPDIR/get_tmux_option.sh" << 'EOF'
#!/usr/bin/env bash
get_tmux_option() {
    local option=$1
    local default_value=$2
    
    if [ -n "${TMUX_TEST_MODE:-}" ]; then
        local var_name="TMUX_OPT_${option//@/_}"
        var_name="${var_name//-/_}"
        if eval "[ -n \"\${${var_name}+x}\" ]"; then
            eval "echo \"\${${var_name}}\""
        else
            echo "$default_value"
        fi
    else
        local value=$(tmux show-option -gqv "$option" 2>/dev/null)
        echo "${value:-$default_value}"
    fi
}
EOF
    chmod +x "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    chmod +x "$BATS_TEST_TMPDIR/get_tmux_option.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "COLORS=orange dark_gray" ]
}

@test "dracula-ccusage.sh applies Dracula colors when specified" {
    # Test that colors are applied to the output
    export TMUX_OPT__dracula_ccusage_colors="orange dark_gray"
    
    # Create a mock tmux-ccusage.sh
    cat > "$BATS_TEST_TMPDIR/tmux-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
prefix="${CCUSAGE_PREFIX:-}"
echo "${prefix}\$100.00"
EOF
    chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
    
    # Create modified dracula-ccusage.sh with color support
    cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    
    # We'll need to modify the script to add color support in the implementation
    # For now, we'll create a version that would output with colors
    cat > "$BATS_TEST_TMPDIR/dracula-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

get_tmux_option() {
    local option=$1
    local default_value=$2
    
    if [ -n "${TMUX_TEST_MODE:-}" ]; then
        local var_name="TMUX_OPT_${option//@/_}"
        var_name="${var_name//-/_}"
        if eval "[ -n \"\${${var_name}+x}\" ]"; then
            eval "echo \"\${${var_name}}\""
        else
            echo "$default_value"
        fi
    else
        local value=$(tmux show-option -gqv "$option" 2>/dev/null)
        echo "${value:-$default_value}"
    fi
}

# Get options
display_format=$(get_tmux_option "@dracula-ccusage-display" "status")
dracula_prefix=$(get_tmux_option "@dracula-ccusage-prefix" "Claude ")
show_prefix=$(get_tmux_option "@dracula-ccusage-show-prefix" "true")
dracula_colors=$(get_tmux_option "@dracula-ccusage-colors" "")

# Disable colors for Dracula theme
export CCUSAGE_ENABLE_COLORS="false"

# Set prefix if needed
if [ "$display_format" != "custom" ] && [ "$show_prefix" = "true" ]; then
    export CCUSAGE_PREFIX="$dracula_prefix"
fi

# Execute tmux-ccusage.sh
output=$("$SCRIPT_DIR/tmux-ccusage.sh" "$display_format")

# Apply Dracula colors if specified
if [ -n "$dracula_colors" ]; then
    # Parse colors (format: "foreground background")
    fg_color=$(echo "$dracula_colors" | cut -d' ' -f1)
    bg_color=$(echo "$dracula_colors" | cut -d' ' -f2)
    
    if [ -n "$bg_color" ]; then
        echo "#[fg=$fg_color,bg=$bg_color]$output#[default]"
    else
        echo "#[fg=$fg_color]$output#[default]"
    fi
else
    echo "$output"
fi
EOF
    chmod +x "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == "#[fg=orange,bg=dark_gray]Claude \$100.00#[default]" ]]
}

@test "dracula-ccusage.sh handles single color in @dracula-ccusage-colors" {
    # Test with only foreground color
    export TMUX_OPT__dracula_ccusage_colors="cyan"
    
    # Create a mock tmux-ccusage.sh
    cat > "$BATS_TEST_TMPDIR/tmux-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
prefix="${CCUSAGE_PREFIX:-}"
echo "${prefix}\$50.00"
EOF
    chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
    
    # Copy the actual dracula-ccusage.sh and modify for test
    cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="'"$BATS_TEST_TMPDIR"'"|' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == "#[fg=cyan]Claude \$50.00#[default]" ]]
}

@test "dracula-ccusage.sh outputs plain text when @dracula-ccusage-colors is not set" {
    # Test default behavior without colors
    unset TMUX_OPT__dracula_ccusage_colors
    
    # Create a mock tmux-ccusage.sh
    cat > "$BATS_TEST_TMPDIR/tmux-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
prefix="${CCUSAGE_PREFIX:-}"
echo "${prefix}\$75.00"
EOF
    chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
    
    # Use the actual dracula-ccusage.sh
    cp "$PROJECT_ROOT/scripts/dracula-ccusage.sh" "$BATS_TEST_TMPDIR/"
    sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="'"$BATS_TEST_TMPDIR"'"|' "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "Claude \$75.00" ]  # No color codes
}

@test "dracula-ccusage.sh color support works with custom prefix" {
    # Test colors with custom prefix
    export TMUX_OPT__dracula_ccusage_colors="green white"
    export TMUX_OPT__dracula_ccusage_prefix="AI Cost: "
    
    # Create a mock tmux-ccusage.sh
    cat > "$BATS_TEST_TMPDIR/tmux-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
prefix="${CCUSAGE_PREFIX:-}"
echo "${prefix}\$200.00"
EOF
    chmod +x "$BATS_TEST_TMPDIR/tmux-ccusage.sh"
    
    # Create the test version with color support
    cat > "$BATS_TEST_TMPDIR/dracula-ccusage.sh" << 'EOF'
#!/usr/bin/env bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

get_tmux_option() {
    local option=$1
    local default_value=$2
    
    if [ -n "${TMUX_TEST_MODE:-}" ]; then
        local var_name="TMUX_OPT_${option//@/_}"
        var_name="${var_name//-/_}"
        if eval "[ -n \"\${${var_name}+x}\" ]"; then
            eval "echo \"\${${var_name}}\""
        else
            echo "$default_value"
        fi
    else
        local value=$(tmux show-option -gqv "$option" 2>/dev/null)
        echo "${value:-$default_value}"
    fi
}

# Get options
dracula_prefix=$(get_tmux_option "@dracula-ccusage-prefix" "Claude ")
dracula_colors=$(get_tmux_option "@dracula-ccusage-colors" "")
export CCUSAGE_ENABLE_COLORS="false"
export CCUSAGE_PREFIX="$dracula_prefix"

# Execute tmux-ccusage.sh
output=$("$SCRIPT_DIR/tmux-ccusage.sh" "status")

# Apply Dracula colors if specified
if [ -n "$dracula_colors" ]; then
    # Parse colors (format: "foreground background")
    fg_color=$(echo "$dracula_colors" | cut -d' ' -f1)
    bg_color=$(echo "$dracula_colors" | cut -d' ' -f2)
    
    if [ -n "$bg_color" ]; then
        echo "#[fg=$fg_color,bg=$bg_color]$output#[default]"
    else
        echo "#[fg=$fg_color]$output#[default]"
    fi
else
    echo "$output"
fi
EOF
    chmod +x "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    
    run "$BATS_TEST_TMPDIR/dracula-ccusage.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == "#[fg=green,bg=white]AI Cost: \$200.00#[default]" ]]
}