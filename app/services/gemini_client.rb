# frozen_string_literal: true

# Gemini API 客戶端
# 支援系統級 API Key 和使用者自帶 API Key (BYOK)
class GeminiClient
  class ConfigurationError < StandardError; end
  class ApiError < StandardError; end

  DEFAULT_MODEL = "gemini-2.0-flash"

  def initialize(api_key: nil)
    @api_key = api_key || ENV["GEMINI_API_KEY"]
    validate_api_key!
  end

  def analyze_content(content, prompt:)
    response = client.generate_content({
      contents: {
        role: "user",
        parts: [{ text: "#{prompt}\n\n---\n\n#{content}" }]
      },
      generation_config: {
        temperature: 0.3,
        max_output_tokens: 2048
      }
    })

    extract_text(response)
  rescue Gemini::Error => e
    raise ApiError, "Gemini API 錯誤: #{e.message}"
  end

  def mvt_validate(content)
    prompt = <<~PROMPT
      你是 MVT (Minimal Viability Test) 內容品質驗證專家。請分析以下數位產品內容，評估四個維度：

      ## MVT 四維度評分標準

      ### Dimension I: 基礎健全性 (Foundations)
      - 是否有隱藏假設 (hidden assumptions)?
      - 概念定義是否清晰?
      - 前提條件是否明確?

      ### Dimension II: 結構完整性 (Structure)
      - 內容結構是否連貫?
      - 是否有斷裂點 (structural breaks)?
      - 章節之間邏輯是否通順?

      ### Dimension III: 推理品質 (Inference)
      - 推論是否有跳躍 (inference gaps)?
      - 因果關係是否合理?
      - 論證是否充分?

      ### Dimension IV: 可驗證性 (Falsifiability)
      - 主張是否可被驗證或反駁?
      - 是否有不可證偽的聲明 (unfalsifiable claims)?
      - 內容是否過於主觀?

      ## 輸出格式 (JSON)
      請以 JSON 格式回覆：
      ```json
      {
        "viable": true/false,
        "overall_score": 0.0-1.0,
        "dimensions": {
          "foundations": { "score": 0.0-1.0, "issues": ["問題1", "問題2"] },
          "structure": { "score": 0.0-1.0, "issues": [] },
          "inference": { "score": 0.0-1.0, "issues": [] },
          "falsifiability": { "score": 0.0-1.0, "issues": [] }
        },
        "summary": "整體評語",
        "recommendations": ["建議1", "建議2"]
      }
      ```

      只回覆 JSON，不要其他文字。
    PROMPT

    response = analyze_content(content, prompt: prompt)
    parse_mvt_response(response)
  end

  private

  def client
    @client ||= Gemini.new(
      credentials: { service: "generative-language-api", api_key: @api_key },
      options: { model: DEFAULT_MODEL }
    )
  end

  def validate_api_key!
    raise ConfigurationError, "未設定 Gemini API Key" if @api_key.blank?
  end

  def extract_text(response)
    response.dig("candidates", 0, "content", "parts", 0, "text") || ""
  end

  def parse_mvt_response(response)
    # 移除 markdown code block 標記
    json_str = response.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip

    JSON.parse(json_str, symbolize_names: true)
  rescue JSON::ParserError => e
    # 如果解析失敗，返回預設結構
    {
      viable: false,
      overall_score: 0.0,
      dimensions: {
        foundations: { score: 0.0, issues: ["無法解析 AI 回應"] },
        structure: { score: 0.0, issues: [] },
        inference: { score: 0.0, issues: [] },
        falsifiability: { score: 0.0, issues: [] }
      },
      summary: "AI 回應解析失敗: #{e.message}",
      recommendations: ["請重新提交驗證"]
    }
  end
end
