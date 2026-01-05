# Digital Gateway Design System

> 統一高品質設計規範 - 適用於 Rails 專案

**Version:** 1.0.0
**Last Updated:** 2026-01-05
**Inspiration:** Cargo.site, Airbnb

---

## 1. Design Philosophy

### 1.1 Core Principles

```
極簡主義 (Minimalism)
├── 大量留白 (Generous whitespace)
├── 清晰層次 (Clear hierarchy)
├── 減法設計 (Design by subtraction)
└── 內容優先 (Content first)
```

**關鍵理念：**
- **Less is more** - 每個元素都必須有存在的理由
- **Quiet confidence** - 不靠花俏吸引眼球，靠品質說話
- **Functional beauty** - 美感來自功能性，不是裝飾

### 1.2 Design DNA

| Aspect | Approach |
|--------|----------|
| Color | 單色系為主，neutral palette |
| Typography | 大字體、輕量字重、負字距 |
| Spacing | 慷慨的留白，呼吸感 |
| Animation | 微妙、快速、有目的 |
| Interaction | 明確的 hover 狀態，無驚喜 |

---

## 2. Visual System

### 2.1 Color Palette

```css
/* Primary - Neutral Scale */
--neutral-50:  #fafafa;   /* Background subtle */
--neutral-100: #f5f5f5;   /* Background muted */
--neutral-200: #e5e5e5;   /* Border light */
--neutral-300: #d4d4d4;   /* Border default */
--neutral-400: #a3a3a3;   /* Text muted */
--neutral-500: #737373;   /* Text secondary */
--neutral-600: #525252;   /* Text tertiary */
--neutral-700: #404040;   /* Hover states */
--neutral-900: #171717;   /* Text primary, Buttons */

/* Semantic Colors - Minimal use */
--green-50:  #f0fdf4;     /* Success background */
--green-600: #16a34a;     /* Success text */
--green-700: #15803d;     /* Success emphasis */

--red-50:  #fef2f2;       /* Error background */
--red-600: #dc2626;       /* Error text */

--yellow-50:  #fefce8;    /* Warning background */
--yellow-700: #a16207;    /* Warning text */
```

### 2.2 Typography

```css
/* Font Stack */
font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;

/* Import */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600&display=swap');

/* Scale */
--text-xs:   0.75rem;   /* 12px - Labels, metadata */
--text-sm:   0.875rem;  /* 14px - Body small, buttons */
--text-base: 1rem;      /* 16px - Body default */
--text-lg:   1.125rem;  /* 18px - Body large */
--text-xl:   1.25rem;   /* 20px - Subheadings */
--text-2xl:  1.5rem;    /* 24px - Section titles */
--text-3xl:  1.875rem;  /* 30px - Page titles */
--text-4xl:  2.25rem;   /* 36px - Hero small */
--text-5xl:  3rem;      /* 48px - Hero medium */
--text-7xl:  4.5rem;    /* 72px - Hero large */

/* Weights */
--font-light:  300;     /* Hero text, large displays */
--font-normal: 400;     /* Body text */
--font-medium: 500;     /* Emphasis, buttons */
--font-semibold: 600;   /* Strong emphasis (rare) */

/* Letter Spacing */
--tracking-tight:  -0.025em;  /* Headlines */
--tracking-wider:  0.05em;    /* Labels, uppercase */
```

### 2.3 Spacing System

```css
/* Base unit: 4px */
--space-1:  0.25rem;   /* 4px */
--space-2:  0.5rem;    /* 8px */
--space-3:  0.75rem;   /* 12px */
--space-4:  1rem;      /* 16px */
--space-6:  1.5rem;    /* 24px */
--space-8:  2rem;      /* 32px */
--space-12: 3rem;      /* 48px */
--space-16: 4rem;      /* 64px */
--space-24: 6rem;      /* 96px */
--space-32: 8rem;      /* 128px */

/* Section Spacing */
Page vertical padding: py-16 (64px)
Section gap: space-y-12 to space-y-16
Card internal padding: p-6 (24px)
```

---

## 3. Component Patterns

### 3.1 Buttons

```erb
<!-- Primary Button - Pill style -->
<%= link_to "Action", path,
    class: "px-6 py-3 bg-neutral-900 text-white text-sm font-medium rounded-full hover:bg-neutral-700 transition-colors" %>

<!-- Secondary Button - Border style -->
<%= link_to "Action", path,
    class: "px-6 py-3 border border-neutral-200 text-sm rounded-lg hover:border-neutral-900 transition-colors" %>

<!-- Text Button -->
<%= link_to "Action", path,
    class: "text-sm text-neutral-500 hover:text-neutral-900 transition-colors" %>

<!-- Destructive -->
<%= button_to "Delete", path,
    method: :delete,
    class: "text-sm text-red-600 hover:underline" %>
```

### 3.2 Form Inputs

```erb
<!-- Underline Input Style (Cargo-inspired) -->
<div>
  <%= f.label :field, "Label",
      class: "block text-xs text-neutral-500 uppercase tracking-wider mb-2" %>
  <%= f.text_field :field,
      placeholder: "Placeholder",
      class: "w-full px-0 py-3 border-0 border-b border-neutral-200 focus:border-neutral-900 focus:ring-0 bg-transparent text-sm placeholder-neutral-300 transition-colors" %>
</div>

<!-- Checkbox -->
<label class="flex items-center gap-2 text-sm text-neutral-500 cursor-pointer">
  <%= f.check_box :field,
      class: "w-4 h-4 border-neutral-300 rounded text-neutral-900 focus:ring-0" %>
  Label text
</label>
```

### 3.3 Cards

```erb
<!-- Product Card -->
<article class="space-y-4">
  <div class="aspect-[4/3] bg-neutral-100 rounded-lg overflow-hidden">
    <!-- Image or placeholder -->
  </div>
  <div class="space-y-2">
    <span class="text-xs text-neutral-400 uppercase tracking-wider">Category</span>
    <h3 class="text-lg font-medium group-hover:underline">Title</h3>
    <p class="text-sm text-neutral-500 line-clamp-2">Description</p>
    <span class="text-lg font-medium">NT$ 1,000</span>
  </div>
</article>

<!-- List Card -->
<div class="flex items-center gap-6 p-6 border border-neutral-100 rounded-xl hover:border-neutral-300 transition-colors">
  <div class="w-20 h-20 bg-neutral-100 rounded-lg flex-shrink-0"></div>
  <div class="flex-1 min-w-0">
    <h3 class="font-medium truncate">Title</h3>
    <p class="text-sm text-neutral-500">Subtitle</p>
  </div>
  <svg class="w-5 h-5 text-neutral-300"><!-- Arrow --></svg>
</div>
```

### 3.4 Status Badges

```erb
<span class="px-2 py-0.5 text-xs rounded-full
  <%= case status
      when 'draft' then 'bg-neutral-100 text-neutral-600'
      when 'pending' then 'bg-yellow-50 text-yellow-700'
      when 'active' then 'bg-green-50 text-green-700'
      when 'error' then 'bg-red-50 text-red-700'
      end %>">
  <%= status.humanize %>
</span>
```

### 3.5 Navigation

```erb
<!-- Fixed Minimal Nav -->
<nav class="fixed top-0 left-0 right-0 z-50 bg-white/90 backdrop-blur-sm">
  <div class="max-w-7xl mx-auto px-6 lg:px-8">
    <div class="flex items-center justify-between h-16">
      <!-- Logo - Text only -->
      <%= link_to "Brand", root_path,
          class: "text-lg font-medium tracking-tight hover:opacity-60 transition-opacity" %>

      <!-- Links -->
      <div class="flex items-center gap-8">
        <%= link_to "Link", path,
            class: "text-sm text-neutral-500 hover:text-neutral-900 transition-colors" %>
        <%= link_to "CTA", path,
            class: "text-sm px-4 py-2 bg-neutral-900 text-white rounded-full hover:bg-neutral-700 transition-colors" %>
      </div>
    </div>
  </div>
</nav>
```

### 3.6 Flash Messages

```erb
<!-- Auto-dismiss flash with animation -->
<% if notice %>
  <div class="fixed top-20 left-1/2 -translate-x-1/2 z-50 px-6 py-3 bg-neutral-900 text-white text-sm rounded-full shadow-lg animate-fade-in"
       data-controller="flash" data-flash-delay-value="3000">
    <%= notice %>
  </div>
<% end %>

<style>
  @keyframes fadeIn { from { opacity: 0; transform: translate(-50%, -10px); } to { opacity: 1; transform: translate(-50%, 0); } }
  @keyframes fadeOut { to { opacity: 0; transform: translate(-50%, -10px); } }
  .animate-fade-in { animation: fadeIn 0.3s ease-out; }
  .animate-fade-out { animation: fadeOut 0.3s ease-out forwards; }
</style>
```

---

## 4. Layout Patterns

### 4.1 Page Structure

```erb
<!-- Standard Page -->
<div class="max-w-7xl mx-auto px-6 lg:px-8 py-16">
  <!-- Header -->
  <div class="mb-16">
    <h1 class="text-4xl font-light mb-4">Page Title</h1>
    <p class="text-neutral-500">Subtitle description.</p>
  </div>

  <!-- Content -->
  <div>
    <!-- ... -->
  </div>
</div>

<!-- Centered Form Page -->
<div class="min-h-[80vh] flex items-center justify-center px-6">
  <div class="w-full max-w-sm">
    <h1 class="text-3xl font-light mb-2">Form Title</h1>
    <p class="text-sm text-neutral-500 mb-10">Description.</p>
    <!-- Form -->
  </div>
</div>
```

### 4.2 Grid Systems

```erb
<!-- Product Grid -->
<div class="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
  <!-- Cards -->
</div>

<!-- Detail Page (Airbnb-style) -->
<div class="grid lg:grid-cols-5 gap-16">
  <div class="lg:col-span-3"><!-- Main content --></div>
  <div class="lg:col-span-2">
    <div class="sticky top-24"><!-- Sidebar --></div>
  </div>
</div>

<!-- Dashboard Layout -->
<div class="grid lg:grid-cols-3 gap-12">
  <div class="lg:col-span-2"><!-- Main --></div>
  <div><!-- Actions sidebar --></div>
</div>
```

### 4.3 Container Widths

```
max-w-sm   (24rem/384px)  - Forms, modals
max-w-2xl  (42rem/672px)  - Blog posts, edit forms
max-w-4xl  (56rem/896px)  - Detail pages
max-w-5xl  (64rem/1024px) - Dashboards
max-w-7xl  (80rem/1280px) - Full pages
```

---

## 5. Code Architecture

### 5.1 File Organization

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── home_controller.rb
│   ├── products_controller.rb      # Public
│   ├── seller/                      # Namespaced
│   │   └── products_controller.rb
│   └── api/
│       └── v1/                      # Versioned API
│
├── models/
│   ├── concerns/                    # Shared behavior
│   ├── product.rb
│   └── user.rb
│
├── views/
│   ├── layouts/
│   │   └── application.html.erb
│   ├── shared/                      # Partials
│   │   ├── _flash.html.erb
│   │   └── _nav.html.erb
│   ├── products/
│   │   ├── index.html.erb
│   │   ├── show.html.erb
│   │   └── _card.html.erb          # Component partial
│   └── seller/
│       └── products/
│
├── javascript/
│   └── controllers/                 # Stimulus
│       ├── application.js
│       └── flash_controller.js
│
└── services/                        # Business logic
    └── mvt/
        └── validator.rb
```

### 5.2 Model Patterns

```ruby
# frozen_string_literal: true

class Product < ApplicationRecord
  # 1. Includes
  include Discard::Model
  include AASM

  # 2. Associations
  belongs_to :seller_profile
  has_one :mvt_report, dependent: :destroy
  has_many :orders, dependent: :restrict_with_error

  # 3. State machine
  aasm column: :status, enum: true do
    state :draft, initial: true
    state :published
    # ...
  end

  # 4. Enums
  enum :status, { draft: 0, published: 1 }, default: :draft

  # 5. Validations
  validates :title, presence: true, length: { maximum: 200 }
  validates :price, presence: true, numericality: { greater_than: 0 }

  # 6. Scopes
  scope :available, -> { kept.published }
  scope :by_seller, ->(id) { where(seller_profile_id: id) }

  # 7. Delegations
  delegate :store_name, to: :seller_profile, prefix: true

  # 8. Instance methods
  def content_type
    # Infer from URL extension
  end
end
```

### 5.3 Controller Patterns

```ruby
# frozen_string_literal: true

module Seller
  class ProductsController < ApplicationController
    # 1. Callbacks
    before_action :authenticate_user!
    before_action :ensure_seller!
    before_action :set_product, only: %i[show edit update destroy]

    # 2. Actions (CRUD order)
    def index
      @products = current_seller_profile.products.kept.order(created_at: :desc)
    end

    def show; end

    def new
      @product = current_seller_profile.products.build
    end

    def create
      @product = current_seller_profile.products.build(product_params)

      if @product.save
        redirect_to seller_product_path(@product), notice: "Created"
      else
        render :new, status: :unprocessable_entity
      end
    end

    # 3. Private methods
    private

    def set_product
      @product = current_seller_profile.products.kept.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:title, :description, :price)
    end

    def ensure_seller!
      redirect_to root_path unless current_user.seller?
    end

    def current_seller_profile
      @current_seller_profile ||= current_user.seller_profile
    end
    helper_method :current_seller_profile
  end
end
```

### 5.4 Service Object Pattern

```ruby
# app/services/mvt/validator.rb
module Mvt
  class Validator
    Result = Struct.new(:valid?, :score, :feedback, keyword_init: true)

    def initialize(content)
      @content = content
    end

    def call
      score = calculate_score
      Result.new(
        valid?: score >= 0.7,
        score: score,
        feedback: generate_feedback
      )
    end

    private

    attr_reader :content

    def calculate_score
      # Logic here
    end

    def generate_feedback
      # Logic here
    end
  end
end

# Usage
result = Mvt::Validator.new(content).call
result.valid? # => true/false
result.score  # => 0.85
```

---

## 6. Testing Standards

### 6.1 Request Specs

```ruby
# spec/requests/products_spec.rb
require 'rails_helper'

RSpec.describe "Products", type: :request do
  describe "GET /products" do
    it "returns http success" do
      get products_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /products/:id" do
    let!(:user) { User.create!(email: "test@test.com", password: "password") }
    let!(:seller_profile) { SellerProfile.create!(user: user, status: :verified) }
    let!(:product) do
      Product.create!(
        seller_profile: seller_profile,
        title: "Test",
        price: 100,
        content_url: "https://example.com/content",
        status: :published
      )
    end

    it "returns http success" do
      get product_path(product)
      expect(response).to have_http_status(:success)
    end
  end
end
```

### 6.2 Service Specs

```ruby
# spec/services/mvt/validator_spec.rb
require 'rails_helper'

RSpec.describe Mvt::Validator do
  describe "#call" do
    context "with clean content" do
      it "returns valid result" do
        result = described_class.new("Good content").call
        expect(result.valid?).to be true
        expect(result.score).to be >= 0.7
      end
    end

    context "with problematic content" do
      it "returns invalid result" do
        result = described_class.new("Bad content with issues").call
        expect(result.valid?).to be false
      end
    end
  end
end
```

---

## 7. Error Pages

### 7.1 Minimalist Error Page Template

```html
<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <title>404 - Brand</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500&display=swap" rel="stylesheet">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Inter', -apple-system, sans-serif;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #fff;
      color: #171717;
    }
    .container { text-align: center; padding: 2rem; }
    .code { font-size: 8rem; font-weight: 300; letter-spacing: -0.05em; color: #e5e5e5; }
    h1 { font-size: 1.5rem; font-weight: 400; margin: 2rem 0 1rem; }
    p { font-size: 0.875rem; color: #737373; margin-bottom: 2rem; }
    a {
      display: inline-block;
      padding: 0.75rem 1.5rem;
      background: #171717;
      color: #fff;
      text-decoration: none;
      border-radius: 9999px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="code">404</div>
    <h1>Page not found</h1>
    <p>The page you're looking for doesn't exist.</p>
    <a href="/">Back to home</a>
  </div>
</body>
</html>
```

---

## 8. Checklist for New Projects

### 8.1 Initial Setup

- [ ] Install Tailwind CSS with `rails tailwindcss:install`
- [ ] Add Inter font via Google Fonts
- [ ] Configure neutral color palette
- [ ] Set up Stimulus controllers directory
- [ ] Create flash_controller.js for auto-dismiss

### 8.2 Layout Setup

- [ ] Fixed navigation with backdrop blur
- [ ] Flash message styling with animations
- [ ] Minimal footer
- [ ] Error pages (404, 500)

### 8.3 Design Review

- [ ] All buttons use pill (rounded-full) or rectangle (rounded-lg) consistently
- [ ] Form inputs use underline style
- [ ] Status badges use semantic colors
- [ ] Cards have consistent padding (p-6)
- [ ] Hover states are subtle (opacity, border, underline)
- [ ] No unnecessary decorations

### 8.4 Code Review

- [ ] Controllers follow RESTful patterns
- [ ] Models organized: includes → associations → validations → scopes → methods
- [ ] Services encapsulate business logic
- [ ] Views use partials for repeated components
- [ ] Tests cover happy path and edge cases

---

## 9. Quick Reference

### Tailwind Classes Cheat Sheet

```
/* Typography */
text-xs uppercase tracking-wider    → Labels
text-sm text-neutral-500            → Secondary text
text-lg font-medium                 → Card titles
text-3xl font-light                 → Page titles
text-5xl md:text-7xl font-light     → Hero

/* Spacing */
space-y-4                           → Tight list
space-y-8                           → Card content
space-y-12                          → Sections
gap-8                               → Grid gap
py-16                               → Page padding

/* Borders */
border border-neutral-100           → Subtle
border border-neutral-200           → Default
hover:border-neutral-300            → Hover
rounded-lg                          → Cards
rounded-xl                          → Large cards
rounded-full                        → Buttons, badges

/* Colors */
bg-neutral-50                       → Muted background
bg-neutral-100                      → Card background
bg-neutral-900                      → Primary buttons
text-neutral-400                    → Muted text
text-neutral-500                    → Secondary text
text-neutral-900                    → Primary text
```

---

*This design system ensures consistency across projects while maintaining the minimalist, professional aesthetic inspired by Cargo.site and Airbnb.*
