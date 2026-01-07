# frozen_string_literal: true

# Gemini API 客戶端
# 支援系統級 API Key 和使用者自帶 API Key (BYOK)
# 回傳 Result 物件包含生成文字與 Token 用量
class GeminiClient
  class ConfigurationError < StandardError; end
  class ApiError < StandardError; end

  # Result 物件：包含生成的文字與 Token 用量
  Result = Struct.new(:text, :input_tokens, :output_tokens, :total_tokens, keyword_init: true) do
    def to_h
      { text: text, input_tokens: input_tokens, output_tokens: output_tokens, total_tokens: total_tokens }
    end
  end

  DEFAULT_MODEL = "gemini-2.0-flash"
  MAX_CONTENT_LENGTH = 10_000 # 限制輸入長度

  def initialize(api_key: nil)
    @api_key = api_key || ENV["GEMINI_API_KEY"]
    validate_api_key!
  end

  # @return [GeminiClient::Result] 包含 text 和 token 用量
  def analyze_content(content, prompt:, json_mode: false)
    # 安全處理：清洗 HTML 和限制長度
    sanitized_content = sanitize_input(content)

    generation_config = {
      temperature: 0.3,
      max_output_tokens: 2048
    }

    # JSON Mode (Gemini 1.5+ 支援)
    generation_config[:response_mime_type] = "application/json" if json_mode

    response = client.generate_content({
      contents: {
        role: "user",
        parts: [{ text: "#{prompt}\n\n---\n\n#{sanitized_content}" }]
      },
      generation_config: generation_config
    })

    extract_result(response)
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

    # 取得 Result (含 Tokens)
    result = analyze_content(content, prompt: prompt)

    # 解析 JSON
    parsed_json = parse_mvt_response(result.text)

    # 將 Token 資訊合併回傳
    parsed_json.merge(
      meta: {
        input_tokens: result.input_tokens,
        output_tokens: result.output_tokens,
        total_tokens: result.total_tokens
      }
    )
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

  # 清洗輸入內容，防止注入攻擊
  def sanitize_input(content)
    return "" if content.blank?

    # 移除 HTML 標籤
    sanitized = ActionController::Base.helpers.strip_tags(content.to_s)

    # 限制長度
    sanitized = sanitized.truncate(MAX_CONTENT_LENGTH) if sanitized.length > MAX_CONTENT_LENGTH

    # 移除潛在的 prompt injection 指令
    sanitized.gsub(/ignore\s+(all\s+)?previous\s+instructions?/i, "[BLOCKED]")
             .gsub(/system\s*:\s*/i, "[BLOCKED]")
  end

  # 從 API 回應提取 Result 物件 (含 text + token 用量)
  def extract_result(response)
    text = response.dig("candidates", 0, "content", "parts", 0, "text") || ""
    usage = response["usageMetadata"] || {}

    Result.new(
      text: text,
      input_tokens: usage["promptTokenCount"] || 0,
      output_tokens: usage["candidatesTokenCount"] || 0,
      total_tokens: usage["totalTokenCount"] || 0
    )
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
