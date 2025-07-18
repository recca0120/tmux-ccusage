# tmux-ccusage

A tmux plugin to display Claude API usage information in your status bar.

[![CI](https://github.com/recca0120/tmux-ccusage/actions/workflows/ci.yml/badge.svg)](https://github.com/recca0120/tmux-ccusage/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/recca0120/tmux-ccusage/branch/main/graph/badge.svg)](https://codecov.io/gh/recca0120/tmux-ccusage)
![tmux-ccusage](https://img.shields.io/badge/tmux-ccusage-green)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[繁體中文](README_zh-TW.md) | English

## Features

- 📊 Display daily/monthly/session costs
- 💰 Show remaining subscription quota
- 📈 Usage percentage with color-coded warnings
- ⚡ 30-second caching to minimize API calls
- 🎨 Multiple display formats
- 🔧 Support all ccusage command options
- 🎯 Comprehensive test coverage (TDD)
- 🚀 Pure bash implementation (no dependencies)
- 🎭 Dracula theme integration

## Requirements

- tmux 2.1+
- [ccusage](https://github.com/zckly/ccusage) CLI tool
- bash

### Installing ccusage

```bash
npm install -g ccusage
```

## Installation

### Option 1: Using TPM (Recommended)

1. Add to `.tmux.conf`:

```tmux
set -g @plugin 'recca0120/tmux-ccusage'
```

2. Press `prefix + I` to install

### Option 2: Manual Installation

```bash
git clone https://github.com/recca0120/tmux-ccusage ~/.tmux/plugins/tmux-ccusage
```

Add to `.tmux.conf`:

```tmux
run-shell ~/.tmux/plugins/tmux-ccusage/tmux-ccusage.tmux
```

## Quick Start

### Minimal Setup

Add to `.tmux.conf`:

```tmux
# Show today's cost
set -g status-right 'Claude: #{@ccusage_today} | %H:%M'
```

Reload tmux configuration:

```bash
tmux source-file ~/.tmux.conf
```

### Advanced Setup

```tmux
# Set subscription amount
set -g @ccusage_subscription_amount '200'

# Set warning thresholds
set -g @ccusage_warning_threshold '80'   # Yellow at 80%
set -g @ccusage_critical_threshold '95'  # Red at 95%

# Show full status with colors
set -g status-right 'Claude: #{@ccusage_status} | %H:%M'
```

## Available Format Strings

| Format String | Description | Example Output |
|--------------|-------------|----------------|
| `#{@ccusage_today}` | Today's cost | `$17.96` |
| `#{@ccusage_total}` | Total cost | `$160.55` |
| `#{@ccusage_both}` | Today and total | `Today: $17.96 \| Total: $160.55` |
| `#{@ccusage_monthly}` | Current month cost | `$450.25` |
| `#{@ccusage_remaining}` | Remaining quota | `$39.45/$200` |
| `#{@ccusage_percentage}` | Usage percentage | `80.3%` |
| `#{@ccusage_status}` | Full status with colors | `$160.55/$200 (80.3%)` |
| `#{@ccusage_custom}` | Custom format | Based on your template |

## Configuration

### Basic Settings

```tmux
# Report type: daily, monthly, session, blocks
set -g @ccusage_report_type 'daily'

# Subscription amount (monthly budget)
set -g @ccusage_subscription_amount '200'

# Or use preset plans
set -g @ccusage_subscription_plan 'pro'  # free ($0), pro ($20), team ($25)

# Cache TTL in seconds
set -g @ccusage_cache_ttl '30'
```

### Time Range Settings

```tmux
# Last N days
set -g @ccusage_days '7'

# Date range
set -g @ccusage_since '20250701'  # Start date
set -g @ccusage_until '20250731'  # End date
```

### Custom Format

Use placeholders to create custom formats:

```tmux
# Available placeholders:
# %today - Today's cost
# %total - Total cost
# %monthly - Monthly cost
# %remaining - Remaining amount
# %subscription - Subscription amount
# %percentage - Usage percentage

set -g @ccusage_custom_format 'Today: %today (Total: %total)'
set -g status-right '#{@ccusage_custom} | %H:%M'
```

### Color Settings

```tmux
# Enable/disable colors
set -g @ccusage_enable_colors 'true'

# Custom colors
set -g @ccusage_color_normal 'colour46'   # Green
set -g @ccusage_color_warning 'colour226'  # Yellow
set -g @ccusage_color_critical 'colour196' # Red
```

## Dracula Theme Integration

If you're using [Dracula tmux theme](https://github.com/dracula/tmux), tmux-ccusage integrates automatically!

```tmux
# Install both plugins
set -g @plugin 'dracula/tmux'
set -g @plugin 'recca0120/tmux-ccusage'

# Configure Dracula to show ccusage
set -g @dracula-plugins "battery custom:ccusage weather"

# Choose display format (default: status)
set -g @dracula-ccusage-display "remaining"

# Configure ccusage options
set -g @ccusage_subscription_amount '200'
```

### Dracula Display Formats

- `status` - Full status: `Claude $160.55/$200 (80.3%)`
- `remaining` - Remaining quota: `Claude $39.45/$200`
- `percentage` - Usage percentage: `Claude 80.3%`
- `today` - Today's cost: `Claude $17.96`
- `total` - Total cost: `Claude $160.55`

## Troubleshooting

### No Output Displayed

1. Check if ccusage is installed:
   ```bash
   which ccusage
   ```

2. Test ccusage:
   ```bash
   ccusage -j
   ```

3. Test the plugin directly:
   ```bash
   ~/.tmux/plugins/tmux-ccusage/tmux-ccusage.sh status
   ```

### Clear Cache

```bash
rm -rf ~/.cache/tmux-ccusage/
```

### Configure Claude API Key

ccusage requires an API key:

```bash
export ANTHROPIC_API_KEY="your-api-key"
```

Add this to your shell configuration file (`~/.bashrc` or `~/.zshrc`).

## Example Configurations

### Simple Configuration

```tmux
set -g @plugin 'recca0120/tmux-ccusage'
set -g status-right '#{@ccusage_remaining} | %H:%M'
```

### Full Configuration

```tmux
set -g @plugin 'recca0120/tmux-ccusage'

# Set subscription and thresholds
set -g @ccusage_subscription_amount '200'
set -g @ccusage_warning_threshold '70'
set -g @ccusage_critical_threshold '90'

# Custom format
set -g @ccusage_custom_format 'Claude: %today/%total (%percentage)'

# Use custom format
set -g status-right '#{@ccusage_custom} | %a %h-%d %H:%M'
```

### Multiple Information Display

```tmux
set -g @plugin 'recca0120/tmux-ccusage'

# Show session info on left
set -g status-left '[#S] #{@ccusage_today} |'

# Show quota on right
set -g status-right '| #{@ccusage_remaining} | %H:%M'
```

## License

MIT License - see [LICENSE](LICENSE) file

## Acknowledgments

- [ccusage](https://github.com/zckly/ccusage) - Claude API usage CLI
- [tmux-cpu](https://github.com/tmux-plugins/tmux-cpu) - Plugin architecture inspiration