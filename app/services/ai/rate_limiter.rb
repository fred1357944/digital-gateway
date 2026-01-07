# frozen_string_literal: true

module Ai
  # AI 請求速率限制
  # 使用 Redis 實作，防止濫用
  class RateLimiter
    class RateLimitExceeded < StandardError
      attr_reader :limit, :count, :reset_at

      def initialize(message, limit:, count:, reset_at:)
        @limit = limit
        @count = count
        @reset_at = reset_at
        super(message)
      end
    end

    # 預設限制
    DEFAULT_LIMITS = {
      per_minute: 10,
      per_hour: 100,
      per_day: 500
    }.freeze

    # BYOK 用戶限制 (較寬鬆)
    BYOK_LIMITS = {
      per_minute: 30,
      per_hour: 300,
      per_day: 2000
    }.freeze

    def initialize(user)
      @user = user
      @limits = user.byok? ? BYOK_LIMITS : DEFAULT_LIMITS
    end

    # 檢查是否超過速率限制
    # @return [Hash] { allowed: true/false, counts: {...}, limits: {...} }
    def check
      counts = current_counts
      exceeded = nil

      @limits.each do |window, limit|
        if counts[window] >= limit
          exceeded = { window: window, limit: limit, count: counts[window] }
          break
        end
      end

      if exceeded
        {
          allowed: false,
          exceeded_window: exceeded[:window],
          limit: exceeded[:limit],
          count: exceeded[:count],
          reset_at: reset_time_for(exceeded[:window])
        }
      else
        { allowed: true, counts: counts, limits: @limits }
      end
    end

    # 檢查並拋出例外
    def check!
      result = check
      return result if result[:allowed]

      raise RateLimitExceeded.new(
        "速率限制已達上限（#{result[:count]}/#{result[:limit]} 每#{window_name(result[:exceeded_window])}）",
        limit: result[:limit],
        count: result[:count],
        reset_at: result[:reset_at]
      )
    end

    # 記錄一次請求
    def increment!
      redis_pool do |redis|
        now = Time.current

        # 每分鐘計數
        minute_key = key_for(:per_minute, now)
        redis.incr(minute_key)
        redis.expire(minute_key, 60)

        # 每小時計數
        hour_key = key_for(:per_hour, now)
        redis.incr(hour_key)
        redis.expire(hour_key, 3600)

        # 每日計數
        day_key = key_for(:per_day, now)
        redis.incr(day_key)
        redis.expire(day_key, 86400)
      end
    end

    # 包裝執行：檢查 → 執行 → 計數
    def with_rate_limit
      check!
      result = yield
      increment!
      result
    end

    private

    def current_counts
      redis_pool do |redis|
        now = Time.current
        {
          per_minute: redis.get(key_for(:per_minute, now)).to_i,
          per_hour: redis.get(key_for(:per_hour, now)).to_i,
          per_day: redis.get(key_for(:per_day, now)).to_i
        }
      end
    end

    def key_for(window, time)
      case window
      when :per_minute
        "ai_rate_limit:user:#{@user.id}:minute:#{time.strftime('%Y%m%d%H%M')}"
      when :per_hour
        "ai_rate_limit:user:#{@user.id}:hour:#{time.strftime('%Y%m%d%H')}"
      when :per_day
        "ai_rate_limit:user:#{@user.id}:day:#{time.strftime('%Y%m%d')}"
      end
    end

    def reset_time_for(window)
      case window
      when :per_minute
        Time.current.end_of_minute
      when :per_hour
        Time.current.end_of_hour
      when :per_day
        Time.current.end_of_day
      end
    end

    def window_name(window)
      case window
      when :per_minute then "分鐘"
      when :per_hour then "小時"
      when :per_day then "天"
      end
    end

    def redis_pool
      # 使用 Sidekiq 的 Redis 連線池（如果有的話）
      # 否則創建新連線
      if defined?(Sidekiq) && Sidekiq.redis_pool
        Sidekiq.redis { |conn| yield(conn) }
      elsif defined?(Redis)
        redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"))
        begin
          yield(redis)
        ensure
          redis.close
        end
      else
        # Fallback: 不使用 Redis，直接允許
        Rails.logger.warn "[RateLimiter] Redis not available, skipping rate limit"
        {}
      end
    end
  end
end
