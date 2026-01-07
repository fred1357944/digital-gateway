# frozen_string_literal: true

module Ai
  # 購買決策助手
  # 幫助用戶分析課程是否適合自己
  class DecisionAssistant
    def initialize(product, user_context:, api_key: nil)
      @product = product
      @user_context = user_context
      @client = GeminiClient.new(api_key: api_key)
    end

    def analyze
      result = @client.analyze_content(build_content, prompt: build_prompt)
      parse_response(result.text)
    rescue GeminiClient::ApiError => e
      { success: false, error: e.message }
    end

    private

    def build_content
      <<~CONTENT
        ## 商品資訊
        標題：#{@product.title}
        描述：#{@product.description}
        類型：#{@product.content_type}
        價格：NT$ #{@product.price.to_i}
        難度：#{@product.ai_metadata.dig("difficulty") || "未知"}

        #{ai_summary_section}

        ## 用戶背景
        學習目標：#{@user_context[:goal]}
        目前程度：#{@user_context[:level] || "未知"}
        可投入時間：#{@user_context[:available_hours] || "未知"} 小時/週
      CONTENT
    end

    def ai_summary_section
      return "" unless @product.ai_enhanced?

      <<~SECTION
        ## AI 分析摘要
        #{@product.ai_summary}

        適合人群：
        #{@product.ai_target_audience.map { |a| "- #{a["description"]}" }.join("\n")}
      SECTION
    end

    def build_prompt
      <<~PROMPT
        你是專業學習顧問。請根據用戶背景，分析這個課程是否適合他購買。

        ## 輸出要求（JSON 格式）

        ```json
        {
          "recommendation": "推薦|考慮|不推薦",
          "fit_score": 0-100,
          "reasons": [
            "推薦理由1",
            "推薦理由2",
            "推薦理由3"
          ],
          "concerns": [
            "可能的疑慮或門檻"
          ],
          "alternatives": "如果不適合，建議先學什麼（可選）",
          "summary": "一句話總結建議"
        }
        ```

        ## 評估維度
        1. 目標匹配度：課程內容是否符合用戶學習目標
        2. 程度適配性：課程難度是否匹配用戶當前程度
        3. 時間可行性：用戶時間是否足夠完成課程
        4. 價值合理性：價格是否合理

        只回覆 JSON，不要其他文字。
      PROMPT
    end

    def parse_response(response)
      json_str = response.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip
      data = JSON.parse(json_str, symbolize_names: true)

      {
        success: true,
        recommendation: data[:recommendation],
        fit_score: data[:fit_score],
        reasons: data[:reasons] || [],
        concerns: data[:concerns] || [],
        alternatives: data[:alternatives],
        summary: data[:summary]
      }
    rescue JSON::ParserError => e
      { success: false, error: "分析失敗: #{e.message}" }
    end
  end
end
