# frozen_string_literal: true

module Ai
  # Intent Router - 根據意圖複雜度路由到不同處理模式
  #
  # 參考：Automated Agent Generation 架構
  # - Workflow Mode: 確定性 4 階段管線（簡單任務）
  # - Meta-Agent Mode: 彈性工具存取（複雜任務）
  #
  class IntentRouter
    # 簡單意圖 → Workflow Mode (Gemini Flash, 便宜)
    WORKFLOW_INTENTS = %w[
      search
      filter
      browse
      preview
      summarize
    ].freeze

    # 複雜意圖 → Meta-Agent Mode (需要推理)
    META_AGENT_INTENTS = %w[
      compare
      plan_path
      recommend
      analyze
      decide
      explore_needs
    ].freeze

    class << self
      # 快速意圖分類（使用簡單規則，省 token）
      def classify(query)
        normalized = query.to_s.downcase

        # 規則基礎分類（零成本）
        return :workflow if workflow_keywords?(normalized)
        return :meta_agent if meta_agent_keywords?(normalized)

        # 預設為 workflow（便宜）
        :workflow
      end

      # 執行路由
      def route(query, user: nil)
        mode = classify(query)

        case mode
        when :workflow
          execute_workflow(query, user: user)
        when :meta_agent
          execute_meta_agent(query, user: user)
        end
      end

      # 取得建議的模型
      def suggested_model(intent_type)
        if WORKFLOW_INTENTS.include?(intent_type.to_s)
          { model: "gemini-2.0-flash", cost: :low, mode: :workflow }
        elsif META_AGENT_INTENTS.include?(intent_type.to_s)
          { model: "gemini-2.0-flash-thinking", cost: :medium, mode: :meta_agent }
        else
          { model: "gemini-2.0-flash", cost: :low, mode: :workflow }
        end
      end

      private

      def workflow_keywords?(text)
        keywords = %w[
          搜尋 找 查 看看 有沒有 列出
          search find show list browse
          便宜 平價 入門 基礎
        ]
        keywords.any? { |k| text.include?(k) }
      end

      def meta_agent_keywords?(text)
        keywords = %w[
          比較 對比 哪個好 該選 推薦路徑 學習計畫
          compare which better plan path recommend
          幫我決定 分析 探索 不確定
        ]
        keywords.any? { |k| text.include?(k) }
      end

      def execute_workflow(query, user:)
        # Stage 1: Intent Decomposition (Gemini Flash)
        # Stage 2: Tool Retrieval (本地邏輯)
        # Stage 3: Prompt Generation (模板)
        # Stage 4: Config Assembly & Execute

        Ai::WorkflowExecutor.new(query, user: user).execute
      end

      def execute_meta_agent(query, user:)
        # Meta-Agent with flexible tool access
        Ai::MetaAgent.new(query, user: user).execute
      end
    end
  end
end
