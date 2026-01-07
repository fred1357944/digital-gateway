# frozen_string_literal: true

module Ai
  # Slot Extractor - 從自然語言提取結構化資訊
  #
  # 使用 Gemini 解析用戶輸入，提取：
  # - topic: 想學的主題
  # - budget_max: 預算上限
  # - level: 難度等級
  # - learning_goal: 學習目標
  # - time_commitment: 時間投入
  #
  class SlotExtractor
    LEVELS = %w[入門 進階 專家].freeze
    GOALS = %w[轉職 興趣 加薪 創業 認證].freeze
    TIME_COMMITMENTS = %w[輕量 中等 重量].freeze

    def initialize(api_key: nil)
      @client = GeminiClient.new(api_key: api_key)
    end

    # 從用戶輸入提取 slots
    def extract(query, context: nil)
      return empty_result if query.blank?

      result = @client.analyze_content(
        build_input(query, context),
        prompt: extraction_prompt
      )

      parse_response(result.text)
    rescue GeminiClient::ApiError => e
      Rails.logger.error "[SlotExtractor] API Error: #{e.message}"
      fallback_extraction(query)
    end

    # 處理衝突 slots（如「便宜」+「專業」）
    def resolve_conflicts(slots)
      conflicts = detect_conflicts(slots)
      return { slots: slots, conflicts: [] } if conflicts.empty?

      # 自動解決策略：以最後輸入為準（用戶會話中可覆蓋）
      resolved = slots.dup
      conflicts.each do |conflict|
        Rails.logger.info "[SlotExtractor] Conflict: #{conflict[:type]} - keeping #{conflict[:keep]}"
      end

      { slots: resolved, conflicts: conflicts }
    end

    private

    def extraction_prompt
      <<~PROMPT
        你是 Slot Filling 專家。從用戶輸入提取結構化資訊。

        ## 可提取的 Slots

        1. topic (主題) - 必填，用戶想學什麼
        2. budget_max (預算上限) - 數字，單位 NT$
           - 「便宜」「划算」→ 500
           - 「中等」「一般」→ 1500
           - 「不限預算」→ null
        3. level (難度) - #{LEVELS.join('/')}
           - 「新手」「零基礎」→ 入門
           - 「有經驗」「進一步」→ 進階
           - 「深入」「專業」→ 專家
        4. learning_goal (目標) - #{GOALS.join('/')}
        5. time_commitment (時間投入) - #{TIME_COMMITMENTS.join('/')}
           - 「每天30分鐘」「輕鬆學」→ 輕量
           - 「系統學習」→ 中等
           - 「全職投入」「密集」→ 重量

        ## 輸出 JSON

        ```json
        {
          "topic": "提取的主題",
          "budget_max": 數字或null,
          "level": "入門/進階/專家" 或 null,
          "learning_goal": "目標" 或 null,
          "time_commitment": "時間投入" 或 null,
          "confidence": 0.0-1.0,
          "missing_required": ["缺少的必填項"],
          "clarification_needed": "如需澄清的問題"
        }
        ```

        ## 範例

        輸入：「想學 Rails，預算 2000，新手」
        輸出：{"topic": "Rails", "budget_max": 2000, "level": "入門", "learning_goal": null, "time_commitment": null, "confidence": 0.9, "missing_required": [], "clarification_needed": null}

        輸入：「便宜的程式課」
        輸出：{"topic": "程式", "budget_max": 500, "level": null, "learning_goal": null, "time_commitment": null, "confidence": 0.7, "missing_required": [], "clarification_needed": "請問你是程式新手還是有經驗？"}

        只回覆 JSON。
      PROMPT
    end

    def build_input(query, context)
      parts = ["用戶輸入：#{query}"]
      parts << "對話上下文：#{context}" if context.present?
      parts.join("\n\n")
    end

    def parse_response(response)
      json_str = response.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip
      data = JSON.parse(json_str, symbolize_names: true)

      {
        success: true,
        slots: extract_slots(data),
        confidence: data[:confidence] || 0.5,
        missing_required: data[:missing_required] || [],
        clarification_needed: data[:clarification_needed]
      }
    rescue JSON::ParserError => e
      Rails.logger.error "[SlotExtractor] Parse error: #{e.message}"
      fallback_extraction(response)
    end

    def extract_slots(data)
      {
        topic: data[:topic],
        budget_max: data[:budget_max],
        level: normalize_level(data[:level]),
        learning_goal: normalize_goal(data[:learning_goal]),
        time_commitment: normalize_time(data[:time_commitment])
      }.compact
    end

    def normalize_level(level)
      return nil if level.blank?
      LEVELS.find { |l| level.to_s.include?(l) }
    end

    def normalize_goal(goal)
      return nil if goal.blank?
      GOALS.find { |g| goal.to_s.include?(g) }
    end

    def normalize_time(time)
      return nil if time.blank?
      TIME_COMMITMENTS.find { |t| time.to_s.include?(t) }
    end

    def fallback_extraction(query)
      # 無 AI 的 fallback：簡單關鍵字匹配
      slots = { topic: query }

      # 價格關鍵字
      slots[:budget_max] = 500 if query.match?(/便宜|划算|平價/i)
      slots[:budget_max] = 1500 if query.match?(/中等|一般/i)

      # 難度關鍵字
      slots[:level] = "入門" if query.match?(/新手|入門|零基礎|初學/i)
      slots[:level] = "進階" if query.match?(/進階|有經驗/i)
      slots[:level] = "專家" if query.match?(/專家|深入|專業/i)

      {
        success: true,
        slots: slots.compact,
        confidence: 0.3,
        missing_required: [],
        clarification_needed: nil,
        fallback: true
      }
    end

    def detect_conflicts(slots)
      conflicts = []

      # 衝突：便宜預算 + 專家級
      if slots[:budget_max].to_i < 500 && slots[:level] == "專家"
        conflicts << {
          type: :budget_vs_level,
          message: "預算較低但要求專家級課程",
          keep: :budget_max
        }
      end

      conflicts
    end

    def empty_result
      {
        success: false,
        slots: {},
        confidence: 0,
        missing_required: ["topic"],
        clarification_needed: "請告訴我你想學什麼？"
      }
    end
  end
end
