# Commit 33e43763 測試對照表

## test_json_parser.sh 測試案例對照

### 1. test_get_today_cost
**舊測試 (33e43763):**
- 測試名稱: test_get_today_cost
- 輸入: 多日 JSON (3.20, 130.45, 17.96)
- 預期輸出: "17.96"
- 錯誤訊息: "Should extract today's cost (17.96)"

**新 Bats 測試需要:**
```bats
@test "test_get_today_cost - Should extract today's cost (17.96)" {
    result=$(echo "$MOCK_MULTI_DAY_JSON" | get_today_cost)
    [ "$result" = "17.96" ]
}
```

### 2. test_get_total_cost
**舊測試 (33e43763):**
- 測試名稱: test_get_total_cost
- 輸入: 多日 JSON
- 預期輸出: "160.55"
- 錯誤訊息: "Should extract total cost (160.55)"

### 3. test_get_cost_by_date
**舊測試 (33e43763):**
- 測試名稱: test_get_cost_by_date
- 輸入: 多日 JSON
- 日期參數: "2025-07-16"
- 預期輸出: "130.45"
- 錯誤訊息: "Should extract cost for specific date"

### 需要修改的測試:
1. 所有測試名稱要保持一致
2. 使用相同的多日 JSON 資料
3. 保持相同的預期輸出