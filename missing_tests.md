# 自製測試框架 vs 新 Bats 測試 - 完整比對

## test_json_parser.sh 的測試案例

### 1. test_get_today_cost
**自製測試:**
- 輸入: 多日 JSON (2025-07-15: 3.20, 2025-07-16: 130.45, 2025-07-17: 17.96)
- 預期: "17.96" (最後一天)

**新 Bats 測試:**
- 輸入: 單日 JSON (只有 2025-07-17: 17.96)
- 預期: "17.96"
- ❌ 輸入資料不同！需要補上多日測試

### 2. test_get_cost_by_date
**自製測試:**
- 輸入: 多日 JSON
- 日期: "2025-07-16" (中間日期)
- 預期: "130.45"

**新 Bats 測試:**
- 輸入: 單日 JSON
- 日期: "2025-07-17"
- 預期: "17.96"
- ❌ 測試場景完全不同！需要補上

### 3. test_monthly_json
**自製測試:**
- 有專門的月度 JSON 測試
- 預期: "450.25"

**新 Bats 測試:**
- 有類似測試
- ✅ 已覆蓋

## test_formatter.sh 的測試案例

需要檢查...

## 需要補上的測試:

1. 多日 JSON 的 get_today_cost 測試 (提取最後一天)
2. 多日 JSON 的 get_cost_by_date 測試 (提取中間日期)
3. test_formatter.sh 中可能遺漏的測試
4. test_cache.sh 中可能遺漏的測試
5. test_integration.sh 中可能遺漏的測試