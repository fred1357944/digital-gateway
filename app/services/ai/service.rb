# frozen_string_literal: true

module Ai
  # 統一 AI 服務入口
  #
  # 支援兩種模式：
  # - :economy  → 分層架構，成本最佳化（Workflow + Meta-Agent）
  # - :premium  → 原始服務，品質最佳化（直接呼叫 Gemini）
  #
  # 使用方式：
  #   Ai::Service.search("找 Rails 課程", mode: :economy)
  #   Ai::Service.search("找 Rails 課程", mode: :premium)
  #
  class Service
    MODES = %i[economy premium auto].freeze

    class << self
      # 智慧搜尋
      def search(query, user: nil, mode: :auto)
        mode = resolve_mode(mode, query)

        case mode
        when :economy
          economy_search(query, user)
        when :premium
          premium_search(query, user)
        end
      end

      # 需求探索（多輪對話）
      def explore(query, user: nil, session_id: nil)
        conversation = AiConversation.find_or_create_for_session(
          session_id || SecureRandom.uuid,
          user: user
        )

        service = DemandExplorerService.new(
          user: user,
          api_key: user&.gemini_api_key,
          conversation: conversation
        )

        result = service.explore(query)
        wrap_result(result, :economy, "explore")
      end

      # 商品比較
      def compare(product_ids, user: nil, mode: :auto)
        mode = resolve_mode(mode, "compare")

        case mode
        when :economy
          economy_compare(product_ids, user)
        when :premium
          premium_compare(product_ids, user)
        end
      end

      # 智慧預覽
      def preview(product, user: nil, mode: :premium)
        # 預覽通常需要高品質，預設用 premium
        case mode
        when :economy
          economy_preview(product, user)
        when :premium
          premium_preview(product, user)
        end
      end

      # 購買決策
      def decide(products, context: {}, user: nil, mode: :premium)
        case mode
        when :economy
          economy_decide(products, context, user)
        when :premium
          premium_decide(products, context, user)
        end
      end

      # 取得模式資訊
      def mode_info(mode)
        case mode.to_sym
        when :economy
          {
            name: "經濟模式",
            description: "使用分層架構，自動選擇最便宜的模型",
            cost_level: "低",
            quality_level: "標準",
            features: ["意圖自動路由", "工具化執行", "成本追蹤"],
            estimated_cost_per_call: "$0.0005 - $0.0015"
          }
        when :premium
          {
            name: "專業模式",
            description: "使用完整 AI 能力，提供最佳品質回應",
            cost_level: "中",
            quality_level: "最佳",
            features: ["深度意圖分析", "完整上下文理解", "精準推薦"],
            estimated_cost_per_call: "$0.002 - $0.005"
          }
        when :auto
          {
            name: "自動模式",
            description: "根據查詢複雜度自動選擇最適合的模式",
            cost_level: "變動",
            quality_level: "自適應"
          }
        end
      end

      private

      # 自動決定使用哪種模式
      def resolve_mode(mode, query)
        return mode if %i[economy premium].include?(mode)

        # Auto mode: 根據複雜度決定
        complexity = IntentRouter.classify(query.to_s)

        case complexity
        when :workflow
          :economy
        when :meta_agent
          # 複雜任務可以選擇 premium 以獲得更好品質
          # 但也可以用 economy 的 meta_agent
          :economy # 預設還是省錢
        else
          :economy
        end
      end

      # === Economy Mode 實作 ===

      def economy_search(query, user)
        result = IntentRouter.route(query, user: user)
        wrap_result(result, :economy, "search")
      end

      def economy_compare(product_ids, user)
        tool = Tools::CompareTool.new(
          client: GeminiClient.new(api_key: user&.gemini_api_key),
          user: user
        )
        result = tool.execute(product_ids: product_ids)
        wrap_result(result, :economy, "compare")
      end

      def economy_preview(product, user)
        tool = Tools::PreviewTool.new(
          client: GeminiClient.new(api_key: user&.gemini_api_key),
          user: user
        )
        result = tool.execute(product_id: product.id)
        wrap_result(result, :economy, "preview")
      end

      def economy_decide(products, context, user)
        # 使用 Meta-Agent 處理複雜決策
        query = "幫我決定要買哪個：#{products.map(&:title).join('、')}"
        result = MetaAgent.new(query, user: user).execute
        wrap_result(result, :economy, "decide")
      end

      # === Premium Mode 實作（使用原始服務）===

      def premium_search(query, user)
        advisor = ShoppingAdvisor.new(query, api_key: user&.gemini_api_key)
        result = advisor.search
        wrap_result(result, :premium, "search")
      end

      def premium_compare(product_ids, user)
        products = Product.where(id: product_ids)
        assistant = DecisionAssistant.new(products, api_key: user&.gemini_api_key)
        result = assistant.compare
        wrap_result(result, :premium, "compare")
      end

      def premium_preview(product, user)
        preview = SmartPreview.new(product, api_key: user&.gemini_api_key)
        result = preview.generate
        wrap_result(result, :premium, "preview")
      end

      def premium_decide(products, context, user)
        assistant = DecisionAssistant.new(products, api_key: user&.gemini_api_key)
        result = assistant.recommend(context: context)
        wrap_result(result, :premium, "decide")
      end

      # 包裝結果，加上模式資訊
      def wrap_result(result, mode, operation)
        result.merge(
          _meta: {
            mode: mode,
            operation: operation,
            mode_info: mode_info(mode),
            timestamp: Time.current
          }
        )
      end
    end
  end
end
