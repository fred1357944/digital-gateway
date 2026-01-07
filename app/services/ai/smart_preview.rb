# frozen_string_literal: true

module Ai
  # 智慧課程預覽服務
  # 使用 Gemini API 生成課程摘要、大綱、適合人群
  class SmartPreview
    def initialize(product, api_key: nil)
      @product = product
      @client = GeminiClient.new(api_key: api_key)
    end

    def generate
      response = @client.analyze_content(build_content, prompt: build_prompt)
      result = parse_response(response)

      update_product(result) if result[:success]
      result
    rescue GeminiClient::ApiError => e
      { success: false, error: e.message }
    end

    private

    def build_content
      <<~CONTENT
        商品標題：#{@product.title}
        商品描述：#{@product.description}
        商品類型：#{@product.content_type}
        價格：NT$ #{@product.price.to_i}
      CONTENT
    end

    def build_prompt
      <<~PROMPT
        你是專業課程企劃專家。請分析以下數位商品，生成智慧預覽資訊。

        ## 輸出要求（JSON 格式）

        ```json
        {
          "summary": "一句話摘要（30字內，突出核心價值）",
          "key_benefits": [
            "核心賣點1",
            "核心賣點2",
            "核心賣點3"
          ],
          "outline": [
            {"chapter": "章節1標題", "description": "簡短說明"},
            {"chapter": "章節2標題", "description": "簡短說明"},
            {"chapter": "章節3標題", "description": "簡短說明"}
          ],
          "target_audience": [
            {"type": "適合", "description": "適合人群1"},
            {"type": "適合", "description": "適合人群2"},
            {"type": "不適合", "description": "不適合人群1"}
          ],
          "difficulty": "入門|進階|專家",
          "estimated_hours": 預估學習時數（數字）
        }
        ```

        ## 規則
        1. 只回覆 JSON，不要其他文字
        2. 根據商品內容合理推測章節結構
        3. 如果資訊不足，用「待補充」標記
        4. 保持客觀，不要過度誇大
      PROMPT
    end

    def parse_response(response)
      json_str = response.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip
      data = JSON.parse(json_str, symbolize_names: true)

      {
        success: true,
        data: data
      }
    rescue JSON::ParserError => e
      { success: false, error: "JSON 解析失敗: #{e.message}" }
    end

    def update_product(result)
      @product.update!(
        ai_metadata: result[:data].merge(generated_at: Time.current.iso8601)
      )
    end
  end
end
