# tmux-ccusage

A tmux plugin to display Claude API usage information in your status bar.

![tmux-ccusage demo](https://img.shields.io/badge/tmux-ccusage-green)

## Features

- 📊 Display daily/monthly/session costs
- 💰 Show remaining subscription quota
- 📈 Usage percentage with color-coded warnings
- ⚡ Efficient 30-second caching mechanism
- 🎨 Multiple customizable display formats
- 🔧 Support all ccusage command options
- 🎯 TDD development with comprehensive tests

## Requirements

- tmux 2.1+
- [ccusage](https://github.com/zckly/ccusage) CLI tool (`npm install -g ccusage`)
- jq (for JSON parsing)

## Installation

### Using TPM (Tmux Plugin Manager)

Add plugin to the list of TPM plugins in `.tmux.conf`:

```tmux
set -g @plugin 'recca0120/tmux-ccusage'
```

Press `prefix + I` to fetch the plugin.

### Manual Installation

Clone the repo:

```bash
git clone https://github.com/recca0120/tmux-ccusage ~/clone/path
```

Add this line to `.tmux.conf`:

```tmux
run-shell ~/clone/path/tmux-ccusage.tmux
```

Or use the install script:

```bash
./install.sh
```

## Usage

### Basic Usage

Add any of the supported format strings to your status bar:

```tmux
# Show today's cost
set -g status-right 'Claude: #{ccusage_today} | %H:%M'

# Show total cost
set -g status-right 'Claude Total: #{ccusage_total} | %H:%M'

# Show both today and total
set -g status-right '#{ccusage_both} | %H:%M'

# Show remaining quota
set -g status-right 'Claude: #{ccusage_remaining} | %H:%M'

# Show usage percentage
set -g status-right 'Claude: #{ccusage_percentage} used | %H:%M'

# Show full status with colors
set -g status-right 'Claude: #{ccusage_status} | %H:%M'
```

### Available Format Strings

| Format String | Description | Example Output |
|--------------|-------------|----------------|
| `#{ccusage_today}` | Today's cost | `$17.96` |
| `#{ccusage_total}` | Total cost | `$160.55` |
| `#{ccusage_both}` | Today and total | `Today: $17.96 \| Total: $160.55` |
| `#{ccusage_monthly}` | Current month cost | `$450.25` |
| `#{ccusage_remaining}` | Remaining quota | `$39.45/$200` |
| `#{ccusage_percentage}` | Usage percentage | `80.3%` |
| `#{ccusage_status}` | Full status with colors | `$160.55/$200 (80.3%)` |
| `#{ccusage_custom}` | Custom format | Based on your template |

## Configuration

### Basic Settings

```tmux
# Report type: daily, monthly, session, blocks
set -g @ccusage_report_type 'daily'

# Subscription amount (monthly budget)
set -g @ccusage_subscription_amount '200'

# Or use preset plans
set -g @ccusage_subscription_plan 'pro'  # free, pro, team

# Warning thresholds
set -g @ccusage_warning_threshold '80'   # Yellow at 80%
set -g @ccusage_critical_threshold '95'  # Red at 95%

# Cache settings
set -g @ccusage_cache_ttl '30'          # Cache for 30 seconds
```

### Advanced Options

```tmux
# Time range filters
set -g @ccusage_days '7'                 # Last 7 days
set -g @ccusage_months '1'               # Last month
set -g @ccusage_since '20250701'         # From specific date
set -g @ccusage_until '20250731'         # Until specific date

# Display options
set -g @ccusage_mode 'auto'              # auto, calculate, display
set -g @ccusage_order 'desc'             # desc or asc
set -g @ccusage_breakdown 'true'         # Show per-model breakdown
set -g @ccusage_offline 'true'           # Use cached pricing

# Custom format
set -g @ccusage_custom_format 'C: #{today}/#{total}'
```

### Environment Variables

All settings can be overridden with environment variables:

```bash
export CCUSAGE_SUBSCRIPTION_AMOUNT=500
export CCUSAGE_CACHE_TTL=60
```

## Examples

### Minimal Setup

```tmux
set -g @plugin 'recca0120/tmux-ccusage'
set -g status-right 'Claude: #{ccusage_today} | %H:%M'
```

### Full Featured Setup

```tmux
set -g @plugin 'recca0120/tmux-ccusage'
set -g @ccusage_subscription_amount '200'
set -g @ccusage_warning_threshold '70'
set -g @ccusage_critical_threshold '90'
set -g status-right 'Claude: #{ccusage_status} | %H:%M'
```

### Custom Format

```tmux
set -g @ccusage_custom_format 'Today: #{today} (Total: #{total})'
set -g status-right '#{ccusage_custom} | %H:%M'
```

## Development

### Running Tests

The project uses TDD with comprehensive test coverage:

```bash
# Run all tests
./test/test_runner.sh

# Run specific test suite
./test/run_tests.sh
```

### Project Structure

```
tmux-ccusage/
├── tmux-ccusage.sh      # Main entry point
├── tmux-ccusage.tmux    # TPM plugin file
├── scripts/
│   ├── json_parser.sh   # JSON parsing functions
│   ├── cache.sh         # Cache management
│   └── formatter.sh     # Display formatters
└── test/
    ├── test_*.sh        # Test files
    └── test_runner.sh   # Test runner
```

## Troubleshooting

### No output shown

1. Check if ccusage is installed: `which ccusage`
2. Check if jq is installed: `which jq`
3. Check tmux version: `tmux -V` (requires 2.1+)
4. Try running directly: `./tmux-ccusage.sh`

### Cache issues

Clear the cache:

```bash
rm -rf ~/.cache/tmux-ccusage/
```

### Debug mode

Check the output directly:

```bash
# Test ccusage
ccusage -j

# Test the plugin
CCUSAGE_SUBSCRIPTION_AMOUNT=200 ./tmux-ccusage.sh status
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure all tests pass
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

MIT - see [LICENSE](LICENSE) file for details

## Acknowledgments

- [ccusage](https://github.com/zckly/ccusage) for the Claude API usage CLI
- [tmux-cpu](https://github.com/tmux-plugins/tmux-cpu) for plugin structure inspiration