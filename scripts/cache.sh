#!/usr/bin/env bash

# Cache management for tmux-ccusage

# Default cache settings
CCUSAGE_CACHE_DIR="${CCUSAGE_CACHE_DIR:-$HOME/.cache/tmux-ccusage}"
CCUSAGE_CACHE_TTL="${CCUSAGE_CACHE_TTL:-30}"  # 30 seconds default
CACHE_FILE="$CCUSAGE_CACHE_DIR/ccusage.json"

# Ensure cache directory exists
mkdir -p "$CCUSAGE_CACHE_DIR"

# Write data to cache
write_cache() {
    local data
    data=$(cat)
    
    # Ensure directory exists
    mkdir -p "$CCUSAGE_CACHE_DIR"
    
    # Write to cache file
    echo "$data" > "$CACHE_FILE"
}

# Read data from cache
read_cache() {
    if [ -f "$CACHE_FILE" ]; then
        cat "$CACHE_FILE"
    fi
}

# Check if cache is valid (not expired)
is_cache_valid() {
    # Check if cache file exists
    if [ ! -f "$CACHE_FILE" ]; then
        return 1
    fi
    
    # Get file modification time
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        local file_time=$(stat -f %m "$CACHE_FILE" 2>/dev/null)
    else
        # Linux
        local file_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null)
    fi
    
    # Get current time
    local current_time=$(date +%s)
    
    # Calculate age
    local age=$((current_time - file_time))
    
    # Check if cache is still valid
    if [ "$age" -lt "$CCUSAGE_CACHE_TTL" ]; then
        return 0  # Valid
    else
        return 1  # Expired
    fi
}

# Get data from cache or fetch if needed
get_cached_or_fetch() {
    local report_type="${1:-daily}"
    local args="${2:-}"
    
    # Check if cache is valid
    if is_cache_valid; then
        # Return cached data
        read_cache
    else
        # Fetch fresh data
        local data
        if [ -n "$args" ]; then
            data=$(ccusage "$report_type" $args -j 2>/dev/null)
        else
            data=$(ccusage "$report_type" -j 2>/dev/null)
        fi
        
        # Cache the data if fetch was successful
        if [ $? -eq 0 ] && [ -n "$data" ]; then
            echo "$data" | write_cache
            echo "$data"
        else
            # If fetch failed, try to return stale cache
            read_cache
        fi
    fi
}

# Clear cache
clear_cache() {
    rm -f "$CACHE_FILE"
}