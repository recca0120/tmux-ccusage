# tmux-ccusage

在 tmux 狀態欄中顯示 Claude API 使用資訊的插件。

[![CI](https://github.com/recca0120/tmux-ccusage/actions/workflows/ci.yml/badge.svg)](https://github.com/recca0120/tmux-ccusage/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/recca0120/tmux-ccusage/branch/main/graph/badge.svg)](https://codecov.io/gh/recca0120/tmux-ccusage)
![tmux-ccusage](https://img.shields.io/badge/tmux-ccusage-green)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

繁體中文 | [English](README.md)

## 功能特色

- 📊 顯示每日/每月/階段使用成本
- 💰 顯示剩餘訂閱配額
- 📈 使用百分比與色彩警示
- ⚡ 30 秒快取機制，減少 API 呼叫
- 🎨 多種顯示格式可選擇
- 🔧 支援所有 ccusage 指令選項
- 🎯 完整測試覆蓋 (TDD 開發)
- 🚀 純 bash 實作，無需額外相依套件
- 🎭 支援 Dracula 主題整合

## 系統需求

- tmux 2.1 以上版本
- [ccusage](https://github.com/zckly/ccusage) CLI 工具
- bash

### 安裝 ccusage

```bash
npm install -g ccusage
```

## 安裝方式

### 方法一：使用 TPM (推薦)

1. 在 `.tmux.conf` 中加入：

```tmux
set -g @plugin 'recca0120/tmux-ccusage'
```

2. 按下 `prefix + I` 安裝插件

### 方法二：手動安裝

```bash
git clone https://github.com/recca0120/tmux-ccusage ~/.tmux/plugins/tmux-ccusage
```

在 `.tmux.conf` 中加入：

```tmux
run-shell ~/.tmux/plugins/tmux-ccusage/tmux-ccusage.tmux
```

## 快速開始

### 最簡單的設定

在 `.tmux.conf` 中加入：

```tmux
# 顯示今日花費
set -g status-right 'Claude: #{@ccusage_today} | %H:%M'
```

重新載入 tmux 設定：

```bash
tmux source-file ~/.tmux.conf
```

### 進階設定範例

```tmux
# 設定訂閱方案金額
set -g @ccusage_subscription_amount '200'

# 設定警告門檻
set -g @ccusage_warning_threshold '80'   # 80% 時顯示黃色
set -g @ccusage_critical_threshold '95'  # 95% 時顯示紅色

# 在狀態欄顯示完整狀態（包含顏色）
set -g status-right 'Claude: #{@ccusage_status} | %H:%M'
```

## 可用的顯示格式

| 格式字串 | 說明 | 輸出範例 |
|---------|------|---------|
| `#{@ccusage_today}` | 今日花費 | `$17.96` |
| `#{@ccusage_total}` | 總花費 | `$160.55` |
| `#{@ccusage_both}` | 今日與總計 | `Today: $17.96 \| Total: $160.55` |
| `#{@ccusage_monthly}` | 本月花費 | `$450.25` |
| `#{@ccusage_remaining}` | 剩餘配額 | `$39.45/$200` |
| `#{@ccusage_percentage}` | 使用百分比 | `80.3%` |
| `#{@ccusage_status}` | 完整狀態（含顏色） | `$160.55/$200 (80.3%)` |
| `#{@ccusage_custom}` | 自訂格式 | 根據您的模板 |

## 設定選項

### 基本設定

```tmux
# 報表類型：daily, monthly, session, blocks
set -g @ccusage_report_type 'daily'

# 訂閱金額（每月預算）
set -g @ccusage_subscription_amount '200'

# 或使用預設方案
set -g @ccusage_subscription_plan 'pro'  # free ($0), pro ($20), team ($25)

# 快取時間（秒）
set -g @ccusage_cache_ttl '30'
```

### 時間範圍設定

```tmux
# 最近 N 天
set -g @ccusage_days '7'

# 特定日期範圍
set -g @ccusage_since '20250701'  # 開始日期
set -g @ccusage_until '20250731'  # 結束日期
```

### 自訂顯示格式

使用佔位符號自訂顯示格式：

```tmux
# 可用的佔位符號：
# %today - 今日花費
# %total - 總花費  
# %monthly - 本月花費
# %remaining - 剩餘金額
# %subscription - 訂閱金額
# %percentage - 使用百分比

set -g @ccusage_custom_format '今日: %today (總計: %total)'
set -g status-right '#{@ccusage_custom} | %H:%M'
```

### 色彩設定

```tmux
# 啟用/停用色彩
set -g @ccusage_enable_colors 'true'

# 自訂色彩
set -g @ccusage_color_normal 'colour46'   # 綠色
set -g @ccusage_color_warning 'colour226'  # 黃色
set -g @ccusage_color_critical 'colour196' # 紅色
```

## Dracula 主題整合

如果您使用 [Dracula tmux 主題](https://github.com/dracula/tmux)，tmux-ccusage 會自動整合！

```tmux
# 安裝兩個插件
set -g @plugin 'dracula/tmux'
set -g @plugin 'recca0120/tmux-ccusage'

# 設定 Dracula 顯示 ccusage
set -g @dracula-plugins "battery custom:ccusage weather"

# 選擇顯示格式（預設：status）
set -g @dracula-ccusage-display "remaining"

# 設定 ccusage 選項
set -g @ccusage_subscription_amount '200'
```

### Dracula 顯示格式選項

- `status` - 完整狀態：`Claude $160.55/$200 (80.3%)`
- `remaining` - 剩餘配額：`Claude $39.45/$200`
- `percentage` - 使用百分比：`Claude 80.3%`
- `today` - 今日花費：`Claude $17.96`
- `total` - 總花費：`Claude $160.55`

## 常見問題

### 沒有顯示任何內容

1. 確認 ccusage 已安裝：
   ```bash
   which ccusage
   ```

2. 測試 ccusage 是否正常：
   ```bash
   ccusage -j
   ```

3. 直接執行插件測試：
   ```bash
   ~/.tmux/plugins/tmux-ccusage/tmux-ccusage.sh status
   ```

### 清除快取

```bash
rm -rf ~/.cache/tmux-ccusage/
```

### 設定 Claude API 金鑰

ccusage 需要設定 API 金鑰：

```bash
export ANTHROPIC_API_KEY="your-api-key"
```

建議將此設定加入您的 shell 設定檔（如 `~/.bashrc` 或 `~/.zshrc`）。

## 範例設定

### 簡單設定

```tmux
set -g @plugin 'recca0120/tmux-ccusage'
set -g status-right '#{@ccusage_remaining} | %H:%M'
```

### 完整設定

```tmux
set -g @plugin 'recca0120/tmux-ccusage'

# 設定訂閱金額與警告門檻
set -g @ccusage_subscription_amount '200'
set -g @ccusage_warning_threshold '70'
set -g @ccusage_critical_threshold '90'

# 自訂顯示格式
set -g @ccusage_custom_format 'Claude: %today/%total (%percentage)'

# 使用自訂格式
set -g status-right '#{@ccusage_custom} | %a %h-%d %H:%M'
```

### 多個資訊顯示

```tmux
set -g @plugin 'recca0120/tmux-ccusage'

# 左側顯示階段資訊
set -g status-left '[#S] #{@ccusage_today} |'

# 右側顯示配額資訊
set -g status-right '| #{@ccusage_remaining} | %H:%M'
```

## 授權

MIT License - 詳見 [LICENSE](LICENSE) 檔案

## 致謝

- [ccusage](https://github.com/zckly/ccusage) - Claude API 使用情況 CLI 工具
- [tmux-cpu](https://github.com/tmux-plugins/tmux-cpu) - 插件架構參考