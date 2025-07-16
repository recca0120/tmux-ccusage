#!/usr/bin/env bash

# Cache management for tmux-ccusage

# Default cache settings (evaluated at runtime)
get_cache_dir() {
    echo "${CCUSAGE_CACHE_DIR:-$HOME/.cache/tmux-ccusage}"
}

get_cache_ttl() {
    echo "${CCUSAGE_CACHE_TTL:-30}"
}

get_cache_file() {
    echo "$(get_cache_dir)/ccusage.json"
}

# Write data to cache
write_cache() {
    local data
    data=$(cat)
    
    local cache_dir
    cache_dir=$(get_cache_dir)
    local cache_file
    cache_file=$(get_cache_file)
    
    # Ensure directory exists
    mkdir -p "$cache_dir"
    
    # Write to cache file
    echo "$data" > "$cache_file"
}

# Read data from cache
read_cache() {
    local cache_file
    cache_file=$(get_cache_file)
    
    if [ -f "$cache_file" ]; then
        cat "$cache_file"
    fi
}

# Check if cache is valid (not expired)
is_cache_valid() {
    local cache_file
    cache_file=$(get_cache_file)
    local cache_ttl
    cache_ttl=$(get_cache_ttl)
    
    # Check if cache file exists
    if [ ! -f "$cache_file" ]; then
        return 1
    fi
    
    # Get file modification time
    local file_time
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        file_time=$(stat -f %m "$cache_file" 2>/dev/null)
    else
        # Linux
        file_time=$(stat -c %Y "$cache_file" 2>/dev/null)
    fi
    
    # Get current time
    local current_time
    current_time=$(date +%s)
    
    # Calculate age
    local age
    age=$((current_time - file_time))
    
    # Check if cache is still valid
    if [ "$age" -lt "$cache_ttl" ]; then
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
            data=$(ccusage "$report_type" "$args" -j 2>/dev/null)
        else
            data=$(ccusage "$report_type" -j 2>/dev/null)
        fi
        
        # Cache the data if fetch was successful
        if [ -n "$data" ]; then
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
    local cache_file
    cache_file=$(get_cache_file)
    rm -f "$cache_file"
}