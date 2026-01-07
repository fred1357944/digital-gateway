# frozen_string_literal: true

module Ai
  # AI 使用量服務
  # 整合點數系統、BYOK 邏輯、使用量追蹤
  #
  # 策略：
  # - BYOK 用戶：不扣點，但仍追蹤使用量
  # - 系統 API 用戶：檢查餘額並扣點
  #
  class UsageService
    class InsufficientCreditsError < StandardError; end
    class RateLimitExceededError < StandardError; end

    # 不同操作的點數成本
    CREDIT_COSTS = {
      explore: 2,        # 探索模式對話
      search: 1,         # 搜尋
      compare: 3,        # 比較分析
      mvt_validation: 5, # MVT 驗證
      smart_preview: 2,  # 智慧預覽
      decision_assist: 3 # 決策助手
    }.freeze

    # 免費用戶每日限額
    FREE_DAILY_LIMIT = 10

    def initialize(user)
      @user = user
    end

    # 檢查是否可以執行操作
    # @return [Hash] { allowed: true/false, reason: String, byok: Boolean }
    def can_execute?(action_type)
      action = action_type.to_sym
      cost = CREDIT_COSTS[action] || 1

      # BYOK 用戶：直接允許
      if @user.byok?
        return { allowed: true, byok: true, cost: 0 }
      end

      # 檢查點數餘額
      unless @user.has_credits?(cost)
        return {
          allowed: false,
          reason: "點數不足（需要 #{cost} 點，餘額 #{@user.ai_credits} 點）",
          byok: false,
          cost: cost,
          credits_remaining: @user.ai_credits
        }
      end

      { allowed: true, byok: false, cost: cost, credits_remaining: @user.ai_credits }
    end

    # 執行操作前的預檢
    # @raise [InsufficientCreditsError] 如果點數不足
    def check_and_reserve!(action_type)
      result = can_execute?(action_type)

      unless result[:allowed]
        raise InsufficientCreditsError, result[:reason]
      end

      result
    end

    # 記錄使用量並扣點
    # @param action_type [Symbol] 操作類型
    # @param token_usage [Hash] { input_tokens, output_tokens, total_tokens }
    # @param conversation [AiConversation] 可選
    # @param metadata [Hash] 額外資訊
    def record_usage(action_type:, token_usage: {}, conversation: nil, metadata: {})
      action = action_type.to_sym
      cost = CREDIT_COSTS[action] || 1

      # BYOK 用戶：只記錄，不扣點
      if @user.byok?
        AiCreditTransaction.create!(
          user: @user,
          ai_conversation: conversation,
          amount: 0, # BYOK 不扣點
          action_type: action.to_s,
          token_usage: token_usage,
          metadata: metadata.merge(byok: true)
        )
        return { success: true, byok: true, cost: 0 }
      end

      # 系統 API 用戶：扣點並記錄
      success = @user.deduct_credits!(
        cost,
        action_type: action.to_s,
        token_usage: token_usage,
        conversation: conversation,
        metadata: metadata
      )

      unless success
        raise InsufficientCreditsError, "扣點失敗"
      end

      {
        success: true,
        byok: false,
        cost: cost,
        credits_remaining: @user.reload.ai_credits
      }
    end

    # 包裝執行：檢查 → 執行 → 記錄
    # @yield 實際的 AI 操作
    # @return [Hash] 操作結果
    def with_usage_tracking(action_type:, conversation: nil, metadata: {})
      # 1. 預檢
      check_result = check_and_reserve!(action_type)

      # 2. 執行 AI 操作
      result = yield

      # 3. 記錄使用量
      token_usage = result.respond_to?(:to_h) ? extract_token_usage(result) : {}

      usage_result = record_usage(
        action_type: action_type,
        token_usage: token_usage,
        conversation: conversation,
        metadata: metadata
      )

      # 4. 合併結果
      if result.is_a?(Hash)
        result.merge(_usage: usage_result)
      else
        { result: result, _usage: usage_result }
      end
    end

    # 使用量統計
    def usage_stats
      {
        credits_remaining: @user.ai_credits,
        byok: @user.byok?,
        today_usage: @user.today_ai_usage,
        month_usage: @user.month_ai_usage,
        total_transactions: @user.ai_credit_transactions.count
      }
    end

    private

    def extract_token_usage(result)
      if result.is_a?(GeminiClient::Result)
        {
          input_tokens: result.input_tokens,
          output_tokens: result.output_tokens,
          total_tokens: result.total_tokens
        }
      elsif result.is_a?(Hash)
        result[:token_usage] || result.dig(:meta) || {}
      else
        {}
      end
    end
  end
end
