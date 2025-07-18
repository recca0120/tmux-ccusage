# tmux-ccusage

A tmux plugin to display Claude API usage information in your status bar.

[![CI](https://github.com/recca0120/tmux-ccusage/actions/workflows/ci.yml/badge.svg)](https://github.com/recca0120/tmux-ccusage/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/recca0120/tmux-ccusage/branch/main/graph/badge.svg)](https://codecov.io/gh/recca0120/tmux-ccusage)
![tmux-ccusage](https://img.shields.io/badge/tmux-ccusage-green)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

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
- bc or awk (optional, for decimal arithmetic)

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
set -g status-right 'Claude: #(@ccusage_today) | %H:%M'

# Show total cost
set -g status-right 'Claude Total: #(@ccusage_total) | %H:%M'

# Show both today and total
set -g status-right '#(@ccusage_both) | %H:%M'

# Show remaining quota
set -g status-right 'Claude: #(@ccusage_remaining) | %H:%M'

# Show usage percentage
set -g status-right 'Claude: #(@ccusage_percentage) used | %H:%M'

# Show full status with colors
set -g status-right 'Claude: #(@ccusage_status) | %H:%M'
```

### Available Format Strings

| Format String | Description | Example Output |
|--------------|-------------|----------------|
| `#(@ccusage_today)` or `#(@ccusage_daily_today)` | Today's cost | `$17.96` |
| `#(@ccusage_total)` or `#(@ccusage_daily_total)` | Total cost | `$160.55` |
| `#(@ccusage_both)` | Today and total | `Today: $17.96 \| Total: $160.55` |
| `#(@ccusage_monthly)` or `#(@ccusage_monthly_current)` | Current month cost | `$450.25` |
| `#(@ccusage_remaining)` | Remaining quota | `$39.45/$200` |
| `#(@ccusage_percentage)` | Usage percentage | `80.3%` |
| `#(@ccusage_status)` | Full status with colors | `$160.55/$200 (80.3%)` |
| `#(@ccusage_custom)` | Custom format | Based on your template |

## Configuration

### Basic Settings

```tmux
# Report type: daily, monthly, session, blocks
set -g @ccusage_report_type 'daily'

# Subscription amount (monthly budget)
set -g @ccusage_subscription_amount '200'

# Or use preset plans
set -g @ccusage_subscription_plan 'pro'  # free ($0), pro ($20), team ($25)

# Warning thresholds
set -g @ccusage_warning_threshold '80'   # Yellow at 80%
set -g @ccusage_critical_threshold '95'  # Red at 95%

# Cache settings
set -g @ccusage_cache_ttl '30'          # Cache for 30 seconds

# Color settings
set -g @ccusage_enable_colors 'true'     # Enable/disable color output
set -g @ccusage_color_normal 'colour46'  # Green
set -g @ccusage_color_warning 'colour226' # Yellow
set -g @ccusage_color_critical 'colour196' # Red
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

# Custom format (supported placeholders: #{daily}, #{today}, #{total})
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
set -g status-right 'Claude: #(@ccusage_today) | %H:%M'
```

### Full Featured Setup

```tmux
set -g @plugin 'recca0120/tmux-ccusage'
set -g @ccusage_subscription_amount '200'
set -g @ccusage_warning_threshold '70'
set -g @ccusage_critical_threshold '90'
set -g status-right 'Claude: #(@ccusage_status) | %H:%M'
```

### Custom Format

```tmux
set -g @ccusage_custom_format 'Today: #{today} (Total: #{total})'
set -g status-right '#(@ccusage_custom) | %H:%M'
```

### Dracula Theme Integration

If you're using the [Dracula tmux theme](https://github.com/dracula/tmux), you can integrate tmux-ccusage as a custom plugin:

#### Installation Steps

1. Install both plugins via TPM:
```tmux
set -g @plugin 'dracula/tmux'
set -g @plugin 'recca0120/tmux-ccusage'
```

2. Create a symlink for Dracula integration:
```bash
# After installing via TPM
ln -sf ~/.tmux/plugins/tmux-ccusage/scripts/ccusage ~/.tmux/plugins/tmux/scripts/ccusage
```

3. Configure in your `.tmux.conf`:
```tmux
# Configure Dracula to show the custom plugin
set -g @dracula-plugins "cpu-usage time custom:ccusage"

# Configure ccusage display format for Dracula
set -g @ccusage_dracula_format 'status'      # Options: daily_today, monthly_current, remaining, percentage, status
set -g @ccusage_dracula_show_icon 'true'     # Show/hide the money icon
set -g @ccusage_dracula_icon '💰'            # Custom icon (default: 💰)

# Set custom plugin colors
set -g @dracula-custom:ccusage-colors "green dark_gray"

# Regular ccusage configuration still applies
set -g @ccusage_subscription_amount '200'
set -g @ccusage_warning_threshold '80'
set -g @ccusage_critical_threshold '95'
```

#### Display Format Options

| Format | Description | Example Output |
|--------|-------------|----------------|
| `daily_today` | Today's cost | `💰 $17.96` |
| `monthly_current` | Current month cost | `💰 $450.25` |
| `remaining` | Remaining quota | `💰 $39.45/$200` |
| `percentage` | Usage percentage | `💰 80.3%` |
| `status` | Full status with colors | `💰 $160.55/$200 (80.3%)` |

Available colors for Dracula custom plugins:
- `white`, `gray`, `dark_gray`, `light_purple`, `dark_purple`
- `cyan`, `green`, `orange`, `red`, `pink`, `yellow`

## Development

### Running Tests

The project uses Bats (Bash Automated Testing System) for comprehensive test coverage:

```bash
# Run all tests
./test/run_tests.sh

# Run tests manually with Bats
bats test/*.bats

# Run with TAP output
bats test/*.bats --formatter tap

# Run specific test file
bats test/json_parser.bats

# Run tmux integration tests
./test/tmux_integration.sh
```

#### Installing Bats

```bash
# macOS
brew install bats-core

# Ubuntu/Debian
sudo apt-get install bats

# Using npm
npm install -g bats
```

### Project Structure

```
tmux-ccusage/
├── tmux-ccusage.sh      # Main entry point
├── tmux-ccusage.tmux    # TPM plugin file
├── dracula-ccusage.sh   # Dracula theme integration wrapper
├── scripts/
│   ├── json_parser.sh   # JSON parsing functions
│   ├── cache.sh         # Cache management
│   └── formatter.sh     # Display formatters
├── test/
│   ├── cache.bats       # Cache functionality tests
│   ├── formatter.bats   # Display formatter tests
│   ├── json_parser.bats # JSON parsing tests
│   ├── integration.bats # Main script integration tests
│   ├── dracula_integration.bats # Dracula theme tests
│   ├── test_helper.bash # Test helper functions
│   ├── run_tests.sh     # Test runner
│   └── tmux_integration.sh # Tmux integration tests
├── install.sh           # Installation script
└── README.md            # This file
```

## Troubleshooting

### No output shown

1. Check if ccusage is installed: `which ccusage`
2. Check tmux version: `tmux -V` (requires 2.1+)
3. Try running directly: `./tmux-ccusage.sh`

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