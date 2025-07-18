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

注意：如果設定了 `@ccusage_prefix`，它會被加在所有標準格式前（自訂格式除外）。

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
# #{today} - 今日花費
# #{total} - 總花費  
# #{monthly} - 本月花費
# #{remaining} - 剩餘金額
# #{subscription} - 訂閱金額
# #{percentage} - 使用百分比
# #{currency} - 貨幣符號
# #{prefix} - 全域前綴

set -g @ccusage_custom_format '今日: #{today} (總計: #{total})'
# 或明確指定貨幣和前綴
set -g @ccusage_custom_format '#{prefix}花費: #{currency}#{today}'
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

### 貨幣符號

```tmux
# 使用自訂貨幣符號（預設：$）
set -g @ccusage_currency_symbol '💰'  # 錢袋表情
# 或其他符號
set -g @ccusage_currency_symbol '€'     # 歐元符號
set -g @ccusage_currency_symbol '¥'     # 日圓符號
set -g @ccusage_currency_symbol '£'     # 英鎊符號
```

### 全域前綴

```tmux
# 為所有輸出加入前綴（自訂格式除外）
set -g @ccusage_prefix 'Claude '      # 預設：空字串
set -g @ccusage_prefix 'AI: '         # 自訂前綴
set -g @ccusage_prefix '🤖 '          # 機器人表情

# 前綴會自動加在標準格式前
# 自訂格式需使用 #{prefix} 佔位符
set -g @ccusage_custom_format '#{prefix}花費： #{today}'
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

### Dracula 整合選項

控制 tmux-ccusage 如何與 Dracula 整合：

```tmux
# 停用自動整合（預設：true）
set -g @ccusage_dracula_auto_integrate 'false'

# 啟用整合時的詳細訊息
set -g @ccusage_dracula_auto_integrate_verbose 'true'

# 停用既有腳本備份（預設：true）
set -g @ccusage_dracula_backup_custom 'false'

# 強制整合（覆蓋自訂腳本）
set -g @ccusage_dracula_auto_integrate 'force'
```

### Dracula 顯示選項

自訂顯示前綴和格式：

```tmux
# 變更前綴（預設："Claude "）
set -g @dracula-ccusage-prefix "AI "

# 完全隱藏前綴
set -g @dracula-ccusage-show-prefix 'false'

# 選擇顯示格式
set -g @dracula-ccusage-display "remaining"
```

| 選項 | 值 | 預設 | 說明 |
|-----|----|----|------|
| `@ccusage_dracula_auto_integrate` | true/false/force | true | 控制自動整合 |
| `@ccusage_dracula_auto_integrate_verbose` | true/false | false | 顯示整合訊息 |
| `@ccusage_dracula_backup_custom` | true/false | true | 備份既有的自訂腳本 |
| `@dracula-ccusage-prefix` | 任何文字 | Claude  | 數值前的前綴文字 |
| `@dracula-ccusage-show-prefix` | true/false | true | 顯示/隱藏前綴 |

### 手動整合

如果您偏好手動設定：

```bash
# 複製整合腳本
cp ~/.tmux/plugins/tmux-ccusage/scripts/dracula-ccusage.sh \
   ~/.tmux/plugins/tmux/scripts/ccusage
chmod +x ~/.tmux/plugins/tmux/scripts/ccusage
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