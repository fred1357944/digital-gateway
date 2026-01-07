# frozen_string_literal: true

module Ai
  # AI 購物顧問搜尋
  # 支援三種模式：
  # - economy: 經濟模式（分層架構，成本最佳化）
  # - premium: 專業模式（原始服務，品質最佳化）
  # - explore: 探索模式（多輪對話，需求探索）
  class SearchController < ApplicationController
    # GET /ai/search
    def index
      @query = params[:q]
      @mode = parse_mode(params[:mode])
      @results = nil
      @mode_info = ::Ai::Service.mode_info(@mode)
      @slots = {}

      return unless @query.present?

      unless api_key_available?
        @error = "請先登入並設定 Gemini API Key 以使用智慧搜尋"
        return
      end

      begin
        result = Timeout.timeout(30) do
          if @mode == :explore
            ::Ai::Service.explore(@query, user: current_user, session_id: session_id)
          else
            ::Ai::Service.search(@query, user: current_user, mode: @mode)
          end
        end

        if result[:success]
          handle_success(result)
        else
          @error = result[:error]
        end
      rescue Timeout::Error
        @error = "搜尋逾時，請稍後再試"
      rescue StandardError => e
        Rails.logger.error "[AI Search] Error: #{e.class} - #{e.message}"
        @error = "搜尋發生錯誤：#{e.message}"
      end
    end

    private

    def session_id
      session[:ai_conversation_id] ||= SecureRandom.uuid
    end

    def parse_mode(mode_param)
      case mode_param&.to_sym
      when :economy, :premium, :explore
        mode_param.to_sym
      else
        :explore # 預設探索模式
      end
    end

    def api_key_available?
      current_user&.gemini_api_key.present? || ENV["GEMINI_API_KEY"].present?
    end

    def handle_success(result)
      # 處理探索模式
      if result.dig(:_meta, :operation) == "explore"
        handle_explore_result(result)
        return
      end

      # 相容兩種模式的回傳格式
      # economy 模式回傳 mode: :workflow 或 :meta_agent
      # premium 模式回傳原始 ShoppingAdvisor 格式（無 mode 或 mode: :premium）
      if result[:mode].in?([:workflow, :meta_agent])
        handle_economy_result(result)
      else
        handle_premium_result(result)
      end

      @actual_mode = result.dig(:_meta, :mode)
      @cost_estimate = result.dig(:cost_estimate) || result.dig(:result, :cost_estimate)
    end

    def handle_explore_result(result)
      @state = result[:state]
      @slots = result[:slots] || {}
      @results = result[:products] || []
      @explanation = result[:explanation]
      @intent = result[:intent]
      @clarification_question = result[:question]
      @actual_mode = :explore
      @cost_estimate = result[:cost_estimate]
      @relaxed = result[:relaxed]
      @relaxed_constraints = result[:relaxed_constraints] || []
      @suggestions = result[:suggestions] || []
    end

    def handle_economy_result(result)
      # Economy 模式的結果結構
      if result[:result]&.dig(:products)
        @results = result[:result][:products].map { |p| product_from_hash(p) }.compact
        @explanation = "找到 #{@results.size} 個商品（經濟模式）"
      elsif result[:products]
        @results = result[:products]
        @explanation = result[:explanation]
      end
      @intent = result[:intent]
    end

    def handle_premium_result(result)
      # Premium 模式的結果結構（原始 ShoppingAdvisor 格式）
      @results = result[:products]
      @intent = result[:intent]
      @explanation = result[:explanation]
    end

    def product_from_hash(hash)
      return nil unless hash[:id]
      Product.find_by(id: hash[:id])
    end
  end
end
