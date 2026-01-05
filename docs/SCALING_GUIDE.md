# Digital Gateway - 擴張指南

> 記錄從 MVP 單機部署到生產級多機部署的升級路徑

---

## 目前架構（MVP 階段）

```
┌─────────────────────────────────────┐
│          Zeabur Container           │
│  ┌─────────────────────────────┐    │
│  │      Rails Application      │    │
│  │  - memory_store (cache)     │    │
│  │  - async adapter (jobs)     │    │
│  │  - async adapter (cable)    │    │
│  └─────────────────────────────┘    │
│              │                      │
│              ▼                      │
│  ┌─────────────────────────────┐    │
│  │        PostgreSQL           │    │
│  │      (單一資料庫)            │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

### 特點
- 單一容器，單一資料庫
- 快取存在記憶體，重啟後清除
- 背景任務在主進程執行
- 適合：MVT 驗證、小流量、開發測試

### 已移除的 Gems（2026-01-05）
```ruby
# 這些 gems 需要多資料庫配置，MVP 階段不需要
# gem "solid_cache"  # 需要 cache 資料庫
# gem "solid_queue"  # 需要 queue 資料庫
# gem "solid_cable"  # 需要 cable 資料庫
```

---

## 擴張階段一：加入 Redis

**觸發條件：**
- 需要跨請求共享快取
- 背景任務開始變多
- 需要 WebSocket 即時功能

### 步驟 1：在 Zeabur 加入 Redis 服務

1. Zeabur Dashboard → Add Service → Redis
2. 獲得 `REDIS_URL` 環境變數

### 步驟 2：設定環境變數

```
REDIS_URL=${REDIS_URI}
```

### 步驟 3：修改 production.rb

```ruby
# config/environments/production.rb

# 快取改用 Redis
config.cache_store = :redis_cache_store, {
  url: ENV["REDIS_URL"],
  expires_in: 1.hour
}

# 背景任務改用 Sidekiq
config.active_job.queue_adapter = :sidekiq
```

### 步驟 4：修改 cable.yml

```yaml
# config/cable.yml
production:
  adapter: redis
  url: <%= ENV["REDIS_URL"] %>
```

### 步驟 5：加入 Sidekiq Procfile

```
# Procfile
web: bundle exec puma -C config/puma.rb -p ${PORT:-8080}
worker: bundle exec sidekiq
release: bundle exec rails db:prepare
```

### 步驟 6：在 Zeabur 加入 Worker 服務

複製 digital-gateway 服務，設定：
- Start Command: `bundle exec sidekiq`
- 共用相同環境變數

---

## 擴張階段二：多容器水平擴展

**觸發條件：**
- 單一容器無法承受流量
- 需要高可用性（HA）

### 架構圖

```
                    ┌──────────────┐
                    │   Load       │
                    │   Balancer   │
                    └──────┬───────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
    ┌───────────┐    ┌───────────┐    ┌───────────┐
    │  Rails 1  │    │  Rails 2  │    │  Rails 3  │
    └─────┬─────┘    └─────┬─────┘    └─────┬─────┘
          │                │                │
          └────────────────┼────────────────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
    ┌───────────┐    ┌───────────┐    ┌───────────┐
    │ PostgreSQL│    │   Redis   │    │  Sidekiq  │
    │  Primary  │    │  Cluster  │    │  Workers  │
    └───────────┘    └───────────┘    └───────────┘
```

### 注意事項

1. **Session 儲存**：改用 Redis 儲存 session
   ```ruby
   # config/initializers/session_store.rb
   Rails.application.config.session_store :redis_store,
     servers: [ENV["REDIS_URL"]],
     expire_after: 1.day
   ```

2. **檔案上傳**：改用雲端儲存（S3/Cloudflare R2）
   ```ruby
   # config/storage.yml
   production:
     service: S3
     bucket: <%= ENV["AWS_BUCKET"] %>
   ```

3. **資料庫連線池**：調整 pool 大小
   ```yaml
   # config/database.yml
   production:
     pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 10 } %>
   ```

---

## 擴張階段三：恢復 Solid 系列（可選）

**如果決定使用 Rails 8 原生方案而非 Redis：**

### 步驟 1：重新加入 Gems

```ruby
# Gemfile
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
```

### 步驟 2：建立多資料庫

在 PostgreSQL 建立額外資料庫：
- `digital_gateway_production_cache`
- `digital_gateway_production_queue`
- `digital_gateway_production_cable`

### 步驟 3：設定 database.yml

```yaml
production:
  primary: &primary_production
    <<: *default
    url: <%= ENV["DATABASE_URL"] %>
  cache:
    <<: *primary_production
    url: <%= ENV["CACHE_DATABASE_URL"] %>
    migrations_paths: db/cache_migrate
  queue:
    <<: *primary_production
    url: <%= ENV["QUEUE_DATABASE_URL"] %>
    migrations_paths: db/queue_migrate
  cable:
    <<: *primary_production
    url: <%= ENV["CABLE_DATABASE_URL"] %>
    migrations_paths: db/cable_migrate
```

### 步驟 4：設定 production.rb

```ruby
config.cache_store = :solid_cache_store
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }
```

### 步驟 5：執行 migrations

```bash
rails db:migrate:cache
rails db:migrate:queue
rails db:migrate:cable
```

---

## 環境變數對照表

| 階段 | 必要變數 |
|------|----------|
| MVP | `DATABASE_URL`, `RAILS_MASTER_KEY`, `SECRET_KEY_BASE` |
| +Redis | 上述 + `REDIS_URL` |
| +S3 | 上述 + `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_BUCKET` |
| +Solid | 上述 + `CACHE_DATABASE_URL`, `QUEUE_DATABASE_URL`, `CABLE_DATABASE_URL` |

---

## 效能監控建議

擴張前應先加入監控，了解瓶頸在哪：

```ruby
# Gemfile
gem "rack-mini-profiler"  # 開發環境效能分析
gem "skylight"            # 或 New Relic, Scout 等 APM
```

### 關鍵指標
- Response Time p95
- Database Query Time
- Background Job Queue Depth
- Memory Usage
- Error Rate

---

## 決策樹

```
需要擴張嗎？
    │
    ├─ Response Time > 500ms ──→ 檢查 N+1 查詢，加 index
    │
    ├─ 記憶體爆掉 ──→ 檢查 memory leak，考慮加容器
    │
    ├─ 背景任務積壓 ──→ 加入 Redis + Sidekiq
    │
    ├─ 需要即時推送 ──→ 加入 Redis for ActionCable
    │
    └─ 流量翻倍 ──→ 水平擴展 + Load Balancer
```

---

## 參考資源

- [Rails 8 Solid 系列文檔](https://guides.rubyonrails.org/active_job_basics.html)
- [Sidekiq Best Practices](https://github.com/sidekiq/sidekiq/wiki/Best-Practices)
- [Zeabur 文檔](https://zeabur.com/docs)
- [Redis Cache Store 配置](https://guides.rubyonrails.org/caching_with_rails.html#activesupport-cache-rediscachestore)

---

*文檔建立：2026-01-05*
*最後更新：2026-01-05*
