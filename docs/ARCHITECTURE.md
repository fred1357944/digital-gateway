# Digital Gateway Architecture

> Rails 專案架構規範與最佳實踐

---

## 1. 技術棧

| Layer | Technology |
|-------|------------|
| Framework | Rails 8.1 |
| Database | PostgreSQL |
| CSS | Tailwind CSS v4 |
| JavaScript | Hotwire (Turbo + Stimulus) |
| Authentication | Devise |
| State Machine | AASM |
| Soft Delete | Discard |
| Testing | RSpec |

---

## 2. 目錄結構

```
digital_gateway/
├── app/
│   ├── controllers/
│   │   ├── concerns/              # 共用 controller 邏輯
│   │   ├── api/v1/                # API 端點（版本化）
│   │   ├── seller/                # 賣家 namespace
│   │   └── webhooks/              # 第三方回調
│   │
│   ├── models/
│   │   ├── concerns/              # 共用 model 邏輯
│   │   ├── user.rb
│   │   ├── product.rb
│   │   ├── order.rb
│   │   ├── seller_profile.rb
│   │   └── mvt_report.rb
│   │
│   ├── services/                  # 業務邏輯服務
│   │   └── mvt/
│   │       ├── validator.rb
│   │       ├── fail_fast_gate.rb
│   │       └── validation_report.rb
│   │
│   ├── jobs/                      # 背景任務
│   │   └── mvt_validation_job.rb
│   │
│   ├── views/
│   │   ├── layouts/
│   │   ├── shared/                # 共用 partials
│   │   ├── devise/                # 認證頁面
│   │   ├── home/
│   │   ├── products/              # 公開產品頁
│   │   └── seller/products/       # 賣家儀表板
│   │
│   └── javascript/
│       └── controllers/           # Stimulus controllers
│
├── config/
│   └── routes.rb
│
├── db/
│   ├── migrate/
│   └── schema.rb
│
├── spec/                          # 測試
│   ├── models/
│   ├── requests/
│   └── services/
│
├── docs/                          # 文件
│   ├── DESIGN_SYSTEM.md
│   └── ARCHITECTURE.md
│
└── public/
    ├── 404.html
    └── 500.html
```

---

## 3. 路由設計

```ruby
Rails.application.routes.draw do
  # 認證
  devise_for :users

  # 首頁
  root "home#index"

  # 公開資源（只讀）
  resources :products, only: %i[index show]

  # 賣家 namespace（需登入 + 賣家權限）
  namespace :seller do
    resources :products do
      member do
        post :submit_review
      end
    end
    resource :profile, only: %i[show edit update]
  end

  # API（版本化）
  namespace :api do
    namespace :v1 do
      resources :products, only: %i[index show]
      resources :orders, only: %i[create show index]

      namespace :buyer do
        resources :orders, only: %i[index show]
      end

      namespace :seller do
        resources :products
        resources :orders, only: :index
      end
    end
  end

  # Webhooks
  namespace :webhooks do
    post "ecpay/notify", to: "ecpay#notify"
  end

  # Health check
  get "up" => "rails/health#show"
end
```

---

## 4. Model 設計模式

### 4.1 狀態機模式

```ruby
class Product < ApplicationRecord
  include AASM

  aasm column: :status, enum: true do
    state :draft, initial: true
    state :pending_review
    state :published
    state :rejected

    event :submit_for_review do
      transitions from: :draft, to: :pending_review
      after { MvtValidationJob.perform_later(id) }
    end

    event :approve do
      transitions from: :pending_review, to: :published
    end

    event :reject do
      transitions from: :pending_review, to: :rejected
    end
  end

  enum :status, {
    draft: 0,
    pending_review: 1,
    published: 2,
    rejected: 3
  }, default: :draft
end
```

### 4.2 軟刪除模式

```ruby
class Product < ApplicationRecord
  include Discard::Model

  # 使用 kept scope 過濾已刪除記錄
  scope :available, -> { kept.published }
end

# 刪除（軟刪除）
product.discard

# 恢復
product.undiscard

# 查詢
Product.kept        # 未刪除
Product.discarded   # 已刪除
Product.with_discarded  # 全部
```

### 4.3 關聯設計

```
User (1) ──── (1) SellerProfile
                    │
                    │ (1:N)
                    ▼
                 Product (1) ──── (1) MvtReport
                    │
                    │ (1:N)
                    ▼
                  Order (N) ──── (1) User (buyer)
                    │
                    │ (1:1)
                    ▼
                AccessToken
```

---

## 5. Service Object 模式

### 5.1 基本結構

```ruby
# app/services/mvt/validator.rb
module Mvt
  class Validator
    # Struct 定義回傳格式
    Result = Struct.new(:score, :violations, :viable?, keyword_init: true)

    def initialize(content)
      @content = content
      @violations = []
    end

    # 單一進入點
    def call
      analyze_content
      Result.new(
        score: calculate_score,
        violations: @violations,
        viable?: @violations.none? { |v| v[:severity] == :fail }
      )
    end

    private

    attr_reader :content

    def analyze_content
      check_dimension_one
      check_dimension_two
      check_dimension_three
      check_dimension_four
    end

    def calculate_score
      return 1.0 if @violations.empty?
      # 計算邏輯
    end
  end
end
```

### 5.2 使用方式

```ruby
# Controller 中使用
result = Mvt::Validator.new(product.content).call

if result.viable?
  product.approve!
else
  product.reject!
  product.create_mvt_report(
    score_mvt: result.score,
    feedback: result.violations.map { |v| v[:message] }.join("\n")
  )
end
```

---

## 6. Controller 模式

### 6.1 Namespace Controller

```ruby
module Seller
  class ProductsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_seller!
    before_action :set_product, only: %i[show edit update destroy]

    def index
      @products = current_seller_profile.products.kept
    end

    private

    def set_product
      @product = current_seller_profile.products.kept.find(params[:id])
    end

    def ensure_seller!
      unless current_user.seller? && current_seller_profile&.verified?
        redirect_to root_path, alert: "需要賣家權限"
      end
    end

    def current_seller_profile
      @current_seller_profile ||= current_user.seller_profile
    end
    helper_method :current_seller_profile
  end
end
```

### 6.2 API Controller

```ruby
module Api
  module V1
    class ProductsController < ApplicationController
      skip_before_action :verify_authenticity_token

      def index
        @products = Product.available.includes(:seller_profile)
        render json: ProductSerializer.new(@products)
      end

      def show
        @product = Product.available.find(params[:id])
        render json: ProductSerializer.new(@product)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Not found" }, status: :not_found
      end
    end
  end
end
```

---

## 7. 背景任務

```ruby
# app/jobs/mvt_validation_job.rb
class MvtValidationJob < ApplicationJob
  queue_as :default

  def perform(product_id)
    product = Product.find(product_id)
    return unless product.pending_review?

    # 取得內容（假設從 URL 抓取）
    content = fetch_content(product.content_url)

    # 驗證
    result = Mvt::Validator.new(content).call

    # 建立報告
    product.create_mvt_report!(
      score_mvt: result.score,
      viable: result.viable?,
      feedback: generate_feedback(result)
    )

    # 更新狀態
    if result.viable?
      product.approve!
    else
      product.reject!
    end
  end

  private

  def fetch_content(url)
    # HTTP 請求邏輯
  end

  def generate_feedback(result)
    result.violations.map { |v| "- #{v[:message]}" }.join("\n")
  end
end
```

---

## 8. 測試策略

### 8.1 測試金字塔

```
        /\
       /  \
      / E2E \        少量
     /______\
    /        \
   /  Request  \     中量
  /______________\
 /                \
/   Unit (Model,   \  大量
/     Service)       \
/____________________\
```

### 8.2 Request Spec

```ruby
RSpec.describe "Products", type: :request do
  describe "GET /products" do
    it "returns http success" do
      get products_path
      expect(response).to have_http_status(:success)
    end

    it "displays published products only" do
      create(:product, status: :published)
      create(:product, status: :draft)

      get products_path
      expect(response.body).to include("Published Product")
      expect(response.body).not_to include("Draft Product")
    end
  end
end
```

### 8.3 Service Spec

```ruby
RSpec.describe Mvt::Validator do
  describe "#call" do
    it "returns perfect score for clean content" do
      result = described_class.new("Clean educational content").call
      expect(result.score).to eq(1.0)
      expect(result.viable?).to be true
    end

    it "detects hidden assumptions" do
      content = "Everyone knows that..."
      result = described_class.new(content).call
      expect(result.violations).to include(
        hash_including(dimension: "I", type: "hidden_assumption")
      )
    end
  end
end
```

---

## 9. 安全考量

### 9.1 Controller 層

```ruby
# 永遠透過關聯查詢，避免越權存取
def set_product
  # ✅ 正確：透過 current_user 的關聯
  @product = current_seller_profile.products.find(params[:id])

  # ❌ 錯誤：直接查詢可能被越權
  # @product = Product.find(params[:id])
end
```

### 9.2 Strong Parameters

```ruby
def product_params
  params.require(:product).permit(
    :title,
    :description,
    :price,
    :content_url,
    :preview_url
    # ❌ 絕不允許：:status, :seller_profile_id
  )
end
```

### 9.3 Soft Delete

```ruby
# 永遠使用 kept scope
Product.kept.find(params[:id])  # ✅
Product.find(params[:id])       # ❌ 可能取到已刪除資料
```

---

## 10. 效能優化

### 10.1 N+1 查詢

```ruby
# ❌ 會產生 N+1
@products = Product.all
@products.each { |p| p.seller_profile.store_name }

# ✅ 使用 includes
@products = Product.includes(:seller_profile).all
```

### 10.2 選擇性載入

```ruby
# 只載入需要的欄位
Product.select(:id, :title, :price).available

# 計數用 count 不要 size
Product.available.count  # SQL COUNT
Product.available.size   # 可能載入全部記錄
```

### 10.3 快取

```erb
<%# 片段快取 %>
<% cache product do %>
  <%= render product %>
<% end %>

<%# 集合快取 %>
<%= render partial: 'product', collection: @products, cached: true %>
```

---

## 11. 部署 Checklist

- [ ] `RAILS_ENV=production`
- [ ] `SECRET_KEY_BASE` 設定
- [ ] Database migration 執行
- [ ] Assets precompile (`rails assets:precompile`)
- [ ] Tailwind build (`rails tailwindcss:build`)
- [ ] Background job worker 啟動
- [ ] Health check endpoint 可訪問
- [ ] Error tracking (Sentry/Rollbar) 設定
- [ ] SSL 憑證配置

---

*這份架構文件確保專案的程式碼品質與一致性，適用於團隊協作與未來維護。*
