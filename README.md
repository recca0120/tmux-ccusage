# tmux-ccusage

A tmux plugin to display Claude API usage information in your status bar.

## Features

- Display daily/monthly costs
- Show remaining subscription quota
- Support all ccusage command types
- Efficient caching mechanism
- Customizable display formats
- Color-coded usage warnings

## Installation

### Using TPM (Tmux Plugin Manager)

Add plugin to the list of TPM plugins in `.tmux.conf`:

```tmux
set -g @plugin 'recca0120/tmux-claude'
```

Press `prefix + I` to fetch the plugin.

### Manual Installation

Clone the repo:

```bash
git clone https://github.com/recca0120/tmux-claude ~/clone/path
```

Add this line to `.tmux.conf`:

```tmux
run-shell ~/clone/path/tmux-ccusage.tmux
```

## Usage

Add any of the supported format strings to your status bar:

```tmux
set -g status-right '#{ccusage_daily_today} | %H:%M'
```

## Configuration

```tmux
# Report type
set -g @ccusage_report_type 'daily'

# Subscription settings
set -g @ccusage_subscription_amount '200'

# Warning thresholds
set -g @ccusage_warning_threshold '80'
set -g @ccusage_critical_threshold '95'
```

## Requirements

- tmux 2.1+
- ccusage CLI tool
- jq (for JSON parsing)

## Testing

Run the test suite:

```bash
./test/run_tests.sh
```

## License

MIT