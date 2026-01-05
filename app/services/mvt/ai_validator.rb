# frozen_string_literal: true

module Mvt
  # AI 驅動的 MVT 驗證器
  # 使用 Gemini API 進行深度內容分析
  # 當 API Key 不可用時，自動降級到規則驗證器
  class AiValidator
    def initialize(api_key: nil)
      @api_key = api_key
      @fallback_validator = Validator.new
    end

    def validate(content, context: {})
      if gemini_available?
        validate_with_gemini(content, context)
      else
        Rails.logger.info "[MVT] Gemini API 不可用，使用規則驗證器"
        @fallback_validator.validate(content, context: context)
      end
    rescue GeminiClient::ApiError => e
      Rails.logger.error "[MVT] Gemini API 錯誤: #{e.message}，降級到規則驗證器"
      @fallback_validator.validate(content, context: context)
    end

    private

    def gemini_available?
      @api_key.present? || ENV["GEMINI_API_KEY"].present?
    end

    def validate_with_gemini(content, context)
      client = GeminiClient.new(api_key: @api_key)
      ai_result = client.mvt_validate(content)

      # 轉換 AI 結果為標準報告格式
      build_report_from_ai(ai_result, context)
    end

    def build_report_from_ai(ai_result, context)
      report = ValidationReport.new(content_name: context[:name] || "Unknown")

      # 設定分數
      report.score_mvt = ai_result[:overall_score] || 0.0

      # 轉換各維度結果
      dimensions_map = {
        foundations: Dimension::FOUNDATIONS,
        structure: Dimension::STRUCTURAL,
        inference: Dimension::INFERENCE,
        falsifiability: Dimension::SCIENTIFIC
      }

      ai_result[:dimensions]&.each do |key, dim_data|
        dimension = dimensions_map[key]
        next unless dimension

        score = dim_data[:score] || 0.0
        severity = score_to_severity(score)

        dim_data[:issues]&.each do |issue|
          report.results << CheckResult.new(
            dimension: dimension,
            severity: severity,
            message: issue,
            principle: key.to_s.upcase[0]
          )
        end
      end

      # 加入 AI 摘要作為額外資訊
      if ai_result[:summary].present?
        report.results << CheckResult.new(
          dimension: "AI Summary",
          severity: Severity::PASS,
          message: ai_result[:summary]
        )
      end

      # 判斷狀態
      report.is_nullity = !ai_result[:viable] && report.score_mvt < 0.3
      report.is_zombie = ai_result[:viable] && report.score_mvt < 0.7

      report
    end

    def score_to_severity(score)
      case score
      when 0.8..1.0 then Severity::PASS
      when 0.5..0.8 then Severity::WARNING
      when 0.3..0.5 then Severity::ZOMBIE
      else Severity::FAIL
      end
    end
  end
end
