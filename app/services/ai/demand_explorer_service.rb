# frozen_string_literal: true

module Ai
  # 需求探索服務 (Needs Explorer)
  #
  # 整合 Slot Filling + Inventory LLM 推薦
  # 流程：
  #   1. SlotExtractor 提取結構化資訊
  #   2. SQL 粗篩商品
  #   3. LLM 精排 + 生成推薦理由
  #
  class DemandExplorerService
    MAX_SQL_RESULTS = 50
    MAX_LLM_RESULTS = 5

    def initialize(user: nil, api_key: nil, conversation: nil)
      @user = user
      @api_key = api_key || user&.gemini_api_key
      @conversation = conversation
      @slot_extractor = SlotExtractor.new(api_key: @api_key)
      @client = GeminiClient.new(api_key: @api_key)
    end

    # 主入口：處理用戶查詢
    def explore(query)
      # 1. 提取 slots
      extraction = @slot_extractor.extract(
        query,
        context: @conversation&.full_context
      )

      unless extraction[:success]
        return {
          success: false,
          error: extraction[:clarification_needed] || "無法理解您的需求",
          state: :gathering
        }
      end

      # 更新對話 slots
      update_conversation_slots(extraction[:slots]) if @conversation

      # 2. 檢查是否需要更多資訊
      if needs_clarification?(extraction)
        return {
          success: true,
          state: :gathering,
          slots: extraction[:slots],
          question: extraction[:clarification_needed] || generate_question(extraction),
          products: []
        }
      end

      # 3. SQL 粗篩
      candidates = sql_filter(extraction[:slots])

      if candidates.empty?
        return handle_no_results(extraction[:slots])
      end

      # 4. LLM 精排
      result = llm_rank_and_recommend(candidates, extraction[:slots], query)

      {
        success: true,
        state: :completed,
        slots: extraction[:slots],
        products: result[:products],
        explanation: result[:explanation],
        intent: result[:intent],
        cost_estimate: result[:cost_estimate]
      }
    rescue GeminiClient::ApiError => e
      { success: false, error: e.message, state: :error }
    end

    private

    def update_conversation_slots(slots)
      @conversation.update_slots(slots)
      @conversation.add_message(role: "user", content: slots.to_json)
    end

    def needs_clarification?(extraction)
      # 必填項缺失
      return true if extraction[:missing_required]&.include?("topic")

      # 信心度太低
      return true if extraction[:confidence].to_f < 0.5

      false
    end

    def generate_question(extraction)
      missing = extraction[:missing_required] || []

      if missing.include?("topic")
        "請告訴我您想學習什麼主題？"
      else
        "您希望課程難度是入門、進階還是專家級？"
      end
    end

    def sql_filter(slots)
      scope = Product.kept.published.includes(:seller_profile, :product_score)

      # 主題關鍵字搜尋
      if slots[:topic].present?
        keywords = slots[:topic].split(/[\s,，、]+/)
        keyword_conditions = keywords.map { "title ILIKE ? OR description ILIKE ?" }
        keyword_values = keywords.flat_map { |k| ["%#{k}%", "%#{k}%"] }
        scope = scope.where(keyword_conditions.join(" OR "), *keyword_values)
      end

      # 預算篩選
      if slots[:budget_max].present?
        scope = scope.where("price <= ?", slots[:budget_max])
      end

      # 難度篩選（從 ai_metadata）
      if slots[:level].present?
        scope = scope.where("ai_metadata->>'difficulty' = ?", slots[:level])
      end

      scope.order(created_at: :desc).limit(MAX_SQL_RESULTS)
    end

    def handle_no_results(slots)
      # 條件鬆弛：移除價格限制再試一次
      relaxed_slots = slots.except(:budget_max)
      candidates = sql_filter(relaxed_slots)

      if candidates.any?
        return {
          success: true,
          state: :completed,
          slots: slots,
          products: candidates.limit(MAX_LLM_RESULTS),
          explanation: "在您的預算範圍內沒有找到課程，以下是相關主題的其他選項：",
          relaxed: true
        }
      end

      {
        success: true,
        state: :completed,
        slots: slots,
        products: [],
        explanation: "抱歉，找不到符合「#{slots[:topic]}」的課程。試試其他關鍵字？"
      }
    end

    def llm_rank_and_recommend(candidates, slots, original_query)
      # 序列化商品資訊
      inventory = serialize_inventory(candidates)
      prompt = build_recommendation_prompt(slots, original_query)

      response = @client.analyze_content(inventory, prompt: prompt)
      parse_recommendation(response, candidates)
    rescue JSON::ParserError => e
      Rails.logger.error "[DemandExplorer] Parse error: #{e.message}"
      fallback_recommendation(candidates, slots)
    end

    def serialize_inventory(products)
      products.map do |p|
        {
          id: p.id,
          title: p.title,
          price: p.price.to_i,
          description: p.description.to_s.truncate(200),
          difficulty: p.ai_metadata&.dig("difficulty"),
          quality_score: p.product_score&.quality_score,
          seller: p.seller_profile&.store_name
        }
      end.to_json
    end

    def build_recommendation_prompt(slots, original_query)
      <<~PROMPT
        你是課程推薦專家。根據用戶需求，從商品列表中選出最適合的 #{MAX_LLM_RESULTS} 個。

        ## 用戶需求
        - 原始查詢：#{original_query}
        - 主題：#{slots[:topic]}
        - 預算上限：#{slots[:budget_max] || '不限'}
        - 難度：#{slots[:level] || '不限'}
        - 學習目標：#{slots[:learning_goal] || '不限'}

        ## 評分標準
        1. 主題相關性 (40%)
        2. 價格合理性 (25%)
        3. 難度匹配度 (20%)
        4. 品質分數 (15%)

        ## 輸出 JSON
        ```json
        {
          "recommended_ids": [id1, id2, ...],
          "explanation": "推薦這些課程的原因（1-2句話）",
          "intent": {
            "user_need": "用戶真正需求的描述",
            "keywords": ["關鍵字1", "關鍵字2"]
          }
        }
        ```

        只回覆 JSON。
      PROMPT
    end

    def parse_recommendation(response, candidates)
      json_str = response.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip
      data = JSON.parse(json_str, symbolize_names: true)

      recommended_ids = data[:recommended_ids] || []
      products = candidates.select { |p| recommended_ids.include?(p.id) }

      # 保持推薦順序
      products = recommended_ids.map { |id| products.find { |p| p.id == id } }.compact

      {
        products: products.take(MAX_LLM_RESULTS),
        explanation: data[:explanation] || "為您推薦以下課程",
        intent: data[:intent] || {},
        cost_estimate: { estimated_cost_usd: 0.001 }
      }
    end

    def fallback_recommendation(candidates, slots)
      # 無 AI 的 fallback：按品質分數排序
      sorted = candidates.sort_by do |p|
        -(p.product_score&.quality_score || 0)
      end

      {
        products: sorted.take(MAX_LLM_RESULTS),
        explanation: "為您推薦「#{slots[:topic]}」相關課程",
        intent: { user_need: slots[:topic], keywords: [slots[:topic]] },
        cost_estimate: { estimated_cost_usd: 0 }
      }
    end
  end
end
