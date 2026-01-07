# Digital Gateway - AI 智慧功能實作報告

> 日期：2026-01-06
> 狀態：初步完成

---

## 已完成功能

### 1. 智慧課程預覽 (Ai::SmartPreview)

**位置：** `app/services/ai/smart_preview.rb`

**功能：**
- 自動生成課程摘要 (summary)
- 提取核心賣點 (key_benefits)
- 推測課程大綱 (outline)
- 分析適合人群 (target_audience)
- 評估難度和預估時數

**資料儲存：** `Product.ai_metadata` (JSONB)

**API：** `POST /ai/products/:product_id/preview`

---

### 2. 購買決策助手 (Ai::DecisionAssistant)

**位置：** `app/services/ai/decision_assistant.rb`

**功能：**
- 接收用戶背景（目標、程度、可用時間）
- 分析課程與用戶的匹配度
- 回傳適合度評分 (0-100)
- 提供推薦理由和注意事項

**API：** `POST /ai/products/:product_id/decision`

**整合位置：** 商品詳情頁側邊欄

---

### 3. AI 購物顧問 (Ai::ShoppingAdvisor)

**位置：** `app/services/ai/shopping_advisor.rb`

**功能：**
- 解析自然語言搜尋意圖
- 提取關鍵字、分類、難度、價格限制
- 轉換為 SQL 查詢條件
- 智慧排序結果（優先 AI 增強商品）

**頁面：** `/ai/search`

**導航：** 頂部導覽列 "AI 顧問" 連結

---

## 技術架構

```
app/
├── services/
│   ├── ai/
│   │   ├── smart_preview.rb       # 智慧預覽服務
│   │   ├── decision_assistant.rb  # 決策助手服務
│   │   └── shopping_advisor.rb    # 購物顧問服務
│   └── gemini_client.rb           # Gemini API 客戶端 (BYOK)
├── controllers/
│   └── ai/
│       ├── previews_controller.rb
│       ├── decisions_controller.rb
│       └── search_controller.rb
├── views/
│   └── ai/
│       ├── previews/_preview.html.erb
│       ├── decisions/_result.html.erb
│       └── search/index.html.erb
└── jobs/
    └── ai/
        └── smart_preview_job.rb   # 非同步處理
```

---

## 安全措施

1. **輸入清洗：** `GeminiClient#sanitize_input`
   - 移除 HTML 標籤
   - 限制內容長度 (10,000 字)
   - 過濾 prompt injection 指令

2. **API Key 加密：** 使用 Lockbox 加密儲存

3. **BYOK 策略：** 用戶自帶 Gemini API Key

---

## 測試覆蓋

```
spec/services/ai/
├── smart_preview_spec.rb      # 2 tests
├── decision_assistant_spec.rb # 2 tests
└── shopping_advisor_spec.rb   # 4 tests

Total: 22 service tests passing
```

---

## 下一步優化建議

來自 Gemini 的建議：

1. **非同步處理** - 已建立 `Ai::SmartPreviewJob`
2. **JSON Mode** - 已支援 `response_mime_type: "application/json"`
3. **搜尋緩存** - 建議使用 Redis 緩存熱門搜尋
4. **Rate Limit** - 建議使用 rack-attack 實作分層限流

---

## 路由

```ruby
namespace :ai do
  get "search", to: "search#index"

  resources :products, only: [] do
    resource :preview, only: :create
    resource :decision, only: :create
  end
end
```

---

*「最好的推薦不是告訴用戶買什麼，而是幫用戶理解自己需要什麼。」*
