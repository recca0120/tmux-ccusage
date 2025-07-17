# tmux-ccusage Dracula Theme Integration

This guide shows how to integrate tmux-ccusage with the Dracula theme for tmux.

## Prerequisites

1. Install Dracula theme for tmux:
   ```bash
   set -g @plugin 'dracula/tmux'
   ```

2. Install tmux-ccusage:
   ```bash
   set -g @plugin 'recca0120/tmux-ccusage'
   ```

## Configuration

### Option 1: Use the provided Dracula configuration

Add to your `~/.tmux.conf`:

```bash
# Load Dracula theme
set -g @plugin 'dracula/tmux'

# Load tmux-ccusage
set -g @plugin 'recca0120/tmux-ccusage'

# Source the Dracula configuration for tmux-ccusage
source-file ~/.tmux/plugins/tmux-ccusage/dracula-theme.conf

# Configure Dracula status bar modules
set -g @dracula-plugins "cpu-usage ram-usage time"
set -g @dracula-show-powerline true
set -g @dracula-show-left-icon session

# Add ccusage to status-right
set -g status-right '#[fg=#44475a,bg=#282a36]#[fg=#f8f8f2,bg=#44475a] #(@ccusage_status) #[fg=#bd93f9,bg=#44475a]#[fg=#282a36,bg=#bd93f9] %H:%M '
```

### Option 2: Manual configuration with Dracula colors

```bash
# Dracula color palette
set -g @ccusage_color_normal '#50fa7b'      # Green
set -g @ccusage_color_warning '#f1fa8c'     # Yellow
set -g @ccusage_color_critical '#ff5555'    # Red

# Configure ccusage subscription
set -g @ccusage_subscription_amount '200'

# Add ccusage to status bar with Dracula colors
set -g status-right '#[fg=#bd93f9]💸 #[fg=#f8f8f2]#(@ccusage_daily_today) | %H:%M'
```

### Option 3: Custom status bar integration

Create your own custom status bar with Dracula colors:

```bash
# Configure tmux-ccusage
set -g @ccusage_subscription_amount '200'
set -g @ccusage_warning_threshold '80'
set -g @ccusage_critical_threshold '95'

# Custom status bar with Dracula colors
set -g status-right '#[fg=#8be9fd]Claude: #(@ccusage_daily_today) #[fg=#6272a4]| #[fg=#50fa7b]#(@ccusage_percentage) #[fg=#6272a4]| #[fg=#f8f8f2]%H:%M'
```

## Display Options

### Minimal display
```bash
set -g status-right '#(@ccusage_daily_today) | %H:%M'
```

### With usage percentage
```bash
set -g status-right '#(@ccusage_percentage) (#(@ccusage_daily_today)) | %H:%M'
```

### With remaining quota
```bash
set -g status-right '#(@ccusage_remaining) | %H:%M'
```

### Full status with colors
```bash
set -g status-right '#[fg=#bd93f9]Claude: #[fg=#f8f8f2]#(@ccusage_status) #[fg=#6272a4]| #[fg=#f8f8f2]%H:%M'
```

## Color Customization

The plugin automatically changes colors based on usage:
- **Green** (#50fa7b): Normal usage (< 80%)
- **Yellow** (#f1fa8c): Warning (80-95%)
- **Red** (#ff5555): Critical (> 95%)

## Reload Configuration

After making changes:
```bash
tmux source-file ~/.tmux.conf
```

## Example Screenshots

The integration will display your Claude API usage in the Dracula-themed status bar with matching colors and style.