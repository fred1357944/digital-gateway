# frozen_string_literal: true

module Ai
  # AI 購物顧問
  # 自然語言搜尋，理解用戶需求推薦商品
  class ShoppingAdvisor
    CATEGORIES = %w[程式開發 設計 行銷 商業 語言 生活技能 其他].freeze
    DIFFICULTY_LEVELS = %w[入門 進階 專家].freeze

    def initialize(query, api_key: nil)
      @query = query
      @client = GeminiClient.new(api_key: api_key)
    end

    def search
      # 1. 解析用戶意圖
      intent = parse_intent

      return intent unless intent[:success]

      # 2. 轉換為資料庫查詢
      products = execute_search(intent)

      # 3. 根據意圖排序結果
      ranked = rank_results(products, intent)

      {
        success: true,
        intent: intent,
        products: ranked,
        explanation: generate_explanation(intent, ranked.count)
      }
    rescue GeminiClient::ApiError => e
      { success: false, error: e.message }
    end

    private

    def parse_intent
      result = @client.analyze_content(@query, prompt: intent_prompt)
      json_str = result.text.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip
      data = JSON.parse(json_str, symbolize_names: true)

      {
        success: true,
        keywords: data[:keywords] || [],
        category: data[:category],
        difficulty: data[:difficulty],
        price_max: data[:price_max],
        intent_type: data[:intent_type] || "search",
        user_need: data[:user_need]
      }
    rescue JSON::ParserError
      # Fallback: 使用原始查詢作為關鍵字
      {
        success: true,
        keywords: @query.split(/\s+/),
        category: nil,
        difficulty: nil,
        price_max: nil,
        intent_type: "search",
        user_need: @query
      }
    end

    def intent_prompt
      <<~PROMPT
        你是搜尋意圖分析專家。請解析用戶的商品搜尋語句。

        可用的分類：#{CATEGORIES.join("、")}
        可用的難度：#{DIFFICULTY_LEVELS.join("、")}

        ## 輸出要求（JSON 格式）

        ```json
        {
          "keywords": ["關鍵字1", "關鍵字2"],
          "category": "最相關的分類（可選）",
          "difficulty": "難度要求（可選）",
          "price_max": 價格上限數字（可選，如提到便宜/平價則設為 500）,
          "intent_type": "search|compare|recommend",
          "user_need": "用一句話描述用戶真正需求"
        }
        ```

        ## 範例
        輸入：「想找便宜的 Rails 入門課」
        輸出：{"keywords": ["Rails", "Ruby on Rails"], "category": "程式開發", "difficulty": "入門", "price_max": 500, "intent_type": "search", "user_need": "學習 Rails 框架基礎"}

        只回覆 JSON。
      PROMPT
    end

    def execute_search(intent)
      scope = Product.kept.published.includes(:seller_profile, :product_score)

      # 關鍵字搜尋（標題或描述）
      if intent[:keywords].any?
        keyword_conditions = intent[:keywords].map { |k| "title ILIKE ? OR description ILIKE ?" }
        keyword_values = intent[:keywords].flat_map { |k| ["%#{k}%", "%#{k}%"] }
        scope = scope.where(keyword_conditions.join(" OR "), *keyword_values)
      end

      # 價格篩選
      if intent[:price_max]
        scope = scope.where("price <= ?", intent[:price_max])
      end

      scope.limit(20)
    end

    def rank_results(products, intent)
      products.sort_by do |p|
        score = 0

        # 有 ProductScore 的優先
        if p.product_score
          score += p.product_score.relevance_score
          score += p.product_score.quality_score * 0.5
        end

        # 有 AI 增強的優先
        score += 20 if p.ai_enhanced?

        # 標題完全匹配關鍵字加分
        intent[:keywords].each do |k|
          score += 30 if p.title.downcase.include?(k.downcase)
        end

        -score # 降序排列
      end
    end

    def generate_explanation(intent, count)
      if count.zero?
        "抱歉，找不到符合「#{intent[:user_need]}」的商品。試試其他關鍵字？"
      elsif count < 5
        "找到 #{count} 個符合「#{intent[:user_need]}」的商品。"
      else
        "為您推薦 #{count} 個「#{intent[:user_need]}」相關商品，已按相關度排序。"
      end
    end
  end
end
