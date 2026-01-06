# Digital Gateway 教學報告

## 專案技術選型分析：Ruby on Rails vs 其他框架

---

## 一、為什麼選擇 Ruby on Rails？

### 1.1 快速開發（Convention over Configuration）

Rails 的核心哲學是「慣例優於配置」，減少決策疲勞：

```ruby
# 一行程式碼完成：路由、控制器、模型關聯
resources :products
```

對比 Express.js 需要手動定義每個路由、中間件、驗證...

### 1.2 全棧框架（Batteries Included）

Rails 內建所有 Web 開發需要的元件：

| 功能 | Rails 內建 | Node.js/Python 需要 |
|------|-----------|-------------------|
| ORM | ActiveRecord | Sequelize/SQLAlchemy |
| 認證 | Devise | Passport/Flask-Login |
| 郵件 | ActionMailer | Nodemailer/Flask-Mail |
| 任務 | ActiveJob | Bull/Celery |
| WebSocket | ActionCable | Socket.io/Channels |
| 測試 | RSpec/Minitest | Jest/Pytest |

### 1.3 成熟的生態系統

- 15+ 年歷史，經過大規模驗證（GitHub、Shopify、Airbnb）
- Gem 生態完整，大部分需求都有現成方案
- 文檔和社群資源豐富

---

## 二、框架比較

### 2.1 Ruby on Rails vs Django (Python)

| 面向 | Rails | Django |
|------|-------|--------|
| 語言 | Ruby（優雅、表達力強） | Python（科學計算強） |
| ORM | ActiveRecord（更直觀） | Django ORM（更 Pythonic） |
| Admin | 需第三方 | 內建強大 Admin |
| 學習曲線 | 中等 | 較平緩 |
| 適合場景 | 快速 MVP、電商 | 數據平台、API |

**結論**：兩者能力相當，選擇取決於團隊熟悉度。Rails 更適合快速原型。

### 2.2 Ruby on Rails vs Express/Fastify (Node.js)

| 面向 | Rails | Node.js |
|------|-------|---------|
| 類型 | 全棧框架 | 微框架 |
| 架構 | MVC 嚴格 | 自由組合 |
| 效能 | 中等 | 較高 |
| 開發速度 | 極快 | 需要組裝 |
| 維護性 | 統一慣例 | 依賴團隊規範 |

**結論**：Node.js 更靈活但需要更多架構決策。Rails 更有「指導性」，適合教學。

### 2.3 Ruby on Rails vs Vite + React/Vue (SPA)

| 面向 | Rails | SPA |
|------|-------|-----|
| 渲染 | 伺服器端 | 客戶端 |
| SEO | 天生友好 | 需要 SSR |
| 複雜度 | 單體應用 | 前後端分離 |
| 部署 | 一個服務 | 多個服務 |
| 適合 | 內容網站、電商 | 複雜互動應用 |

**結論**：Rails 8 + Hotwire 已經能達到 SPA 體驗，同時保持簡單架構。

---

## 三、Digital Gateway 專案架構

### 3.1 技術棧

```
┌─────────────────────────────────────────┐
│              Frontend                    │
│  Tailwind CSS v4 + Hotwire (Turbo)      │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│           Ruby on Rails 8.1             │
│  ┌─────────────────────────────────┐    │
│  │ Controllers (MVC)               │    │
│  │ - ProductsController            │    │
│  │ - OrdersController              │    │
│  │ - Seller::ProductsController    │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │ Models (ActiveRecord + AASM)    │    │
│  │ - User (Devise)                 │    │
│  │ - Product (狀態機)              │    │
│  │ - Order (狀態機)                │    │
│  │ - SellerProfile                 │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │ Services                        │    │
│  │ - GeminiClient (AI 驗證)        │    │
│  │ - Mvt::Validator                │    │
│  │ - ContentFetcher                │    │
│  └─────────────────────────────────┘    │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│            PostgreSQL                    │
└─────────────────────────────────────────┘
```

### 3.2 設計模式

| 模式 | 實現 | 用途 |
|------|------|------|
| State Machine | AASM | Product/Order 狀態流轉 |
| Service Object | app/services/ | 封裝複雜業務邏輯 |
| Soft Delete | Discard gem | 資料不實際刪除 |
| BYOK | Lockbox 加密 | 用戶自帶 API Key |
| Background Job | ActiveJob | MVT 驗證異步處理 |

### 3.3 安全措施

```ruby
# 1. 速率限制 (rack-attack)
throttle("api/ip", limit: 100, period: 1.minute)

# 2. SSRF 防護 (ContentFetcher)
raise FetchError if private_ip?(resolved_ip)

# 3. API Key 加密 (Lockbox)
encrypts :gemini_api_key

# 4. 狀態機防護 (AASM)
event :pay do
  transitions from: :pending, to: :paid  # 只能從 pending 付款
end
```

---

## 四、教學重點

### 4.1 適合教學的原因

1. **結構清晰**：MVC 強制分離關注點
2. **慣例統一**：學生不需要做架構決策
3. **錯誤訊息友善**：Rails 錯誤頁面詳細
4. **快速成就感**：scaffold 讓學生快速看到成果
5. **真實世界應用**：電商是最佳教學案例

### 4.2 建議教學順序

```
Week 1: Rails 基礎
├── MVC 概念
├── 路由與控制器
└── ActiveRecord 基礎

Week 2: 用戶系統
├── Devise 認證
├── 角色權限
└── Session 管理

Week 3: 商品管理
├── CRUD 操作
├── 表單處理
├── 圖片上傳

Week 4: 狀態機與業務邏輯
├── AASM 狀態機
├── Service Object
└── Background Job

Week 5: 前端整合
├── Tailwind CSS
├── Hotwire/Turbo
└── Stimulus

Week 6: 部署與維運
├── Docker 容器化
├── CI/CD
└── 監控與日誌
```

### 4.3 學習資源

| 類型 | 資源 |
|------|------|
| 官方文檔 | https://guides.rubyonrails.org |
| 影片課程 | GoRails, Drifting Ruby |
| 書籍 | Agile Web Development with Rails 8 |
| 社群 | Ruby Taiwan, Rails Discord |

---

## 五、與其他語言的教學對比

### Python (Django)
- ✅ 更廣泛的應用（AI/ML）
- ✅ 語法更易學
- ❌ Web 開發不是主場

### JavaScript (Node.js)
- ✅ 前後端統一語言
- ✅ 生態系最大
- ❌ 需要太多架構決策
- ❌ callback/async 概念較難

### Ruby (Rails)
- ✅ 語法優雅，接近自然語言
- ✅ 框架成熟，慣例明確
- ✅ 專注 Web 開發
- ❌ 效能不是最優
- ❌ Ruby 職缺相對較少

---

## 六、結論

### 選擇 Rails 的理由

1. **教學目的**：Rails 的「慣例優於配置」讓學生專注於概念而非配置
2. **真實專案**：Digital Gateway 展示了完整的電商流程
3. **現代功能**：Rails 8 + Hotwire 不輸 SPA 體驗
4. **快速迭代**：MVP 到 v1.0 只需數小時

### 適合人群

- Web 開發初學者
- 需要快速建立 MVP 的創業者
- 想理解全棧架構的工程師

### 不適合場景

- 高併發即時系統（考慮 Elixir/Go）
- 計算密集應用（考慮 Python）
- 需要極致效能（考慮 Rust）

---

## 附錄：專案統計

| 指標 | 數值 |
|------|------|
| 程式碼行數 | ~3000 行 |
| Model 數量 | 6 個 |
| Controller 數量 | 8 個 |
| 測試案例 | 30+ 個 |
| 開發時間 | ~8 小時 |
| Gem 依賴 | 35 個 |

---

*報告產生日期：2026-01-06*
*專案版本：v1.0*
*作者：Claude Code + Fred Lai*
