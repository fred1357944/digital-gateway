# frozen_string_literal: true

# MVT Validator Ruby Version
# 基於 MVT 論文的四維度內容驗證系統
# 移植自 Python mvt_validator_extended.py

module Mvt
  # 嚴重程度
  module Severity
    PASS = "✓"
    WARNING = "⚠"
    FAIL = "✗"
    ZOMBIE = "🧟"   # 結構有問題但可能有用
    NULLITY = "∅"   # 完全無效
  end

  # 四個維度
  module Dimension
    FOUNDATIONS = "Foundations"           # Dim I: 前提與假設
    STRUCTURAL = "Structural Integrity"   # Dim II: 結構保持
    INFERENCE = "Inference Logic"         # Dim III: 推理連續
    SCIENTIFIC = "Scientific Integrity"   # Dim IV: 可證偽性
  end

  # 檢查結果
  class CheckResult
    attr_accessor :dimension, :severity, :message, :evidence, :case_study, :principle

    def initialize(dimension:, severity:, message:, evidence: nil, case_study: nil, principle: nil)
      @dimension = dimension
      @severity = severity
      @message = message
      @evidence = evidence
      @case_study = case_study
      @principle = principle
    end

    def to_h
      {
        dimension: @dimension,
        severity: @severity,
        message: @message,
        evidence: @evidence,
        case_study: @case_study,
        principle: @principle
      }.compact
    end
  end

  # 驗證報告
  class ValidationReport
    attr_accessor :content_name, :timestamp, :results, :score_mvt, :is_zombie, :is_nullity

    def initialize(content_name:)
      @content_name = content_name
      @timestamp = Time.now.iso8601
      @results = []
      @score_mvt = 0.0
      @is_zombie = false
      @is_nullity = false
    end

    def viable?
      !@results.any? { |r| [Severity::FAIL, Severity::NULLITY].include?(r.severity) }
    end

    def has_warnings?
      @results.any? { |r| r.severity == Severity::WARNING }
    end

    def violation_rate
      return 0.0 if @results.empty?
      violations = @results.count { |r| [Severity::WARNING, Severity::FAIL].include?(r.severity) }
      violations.to_f / @results.size
    end

    def to_h
      {
        content_name: @content_name,
        timestamp: @timestamp,
        score_mvt: @score_mvt,
        is_viable: viable?,
        is_zombie: @is_zombie,
        is_nullity: @is_nullity,
        violation_rate: violation_rate,
        results: @results.map(&:to_h)
      }
    end

    def summary
      lines = ["# MVT 驗證報告: #{@content_name}"]
      lines << "時間: #{@timestamp}\n"

      # 狀態摘要
      status = if @is_nullity
                 "**狀態**: NULLITY ∅ — 完全無效，建議刪除\n"
               elsif @is_zombie
                 "**狀態**: ZOMBIE 🧟 — 結構有問題但可能有預測價值\n"
               elsif viable? && !has_warnings?
                 "**狀態**: 通過 ✓\n"
               elsif viable?
                 "**狀態**: 通過（有警告）⚠\n"
               else
                 "**狀態**: DOA ✗ — 不可行\n"
               end
      lines << status

      lines << "**Score_MVT**: #{format('%.3f', @score_mvt)}"
      lines << "**Violation Rate**: #{format('%.1f%%', violation_rate * 100)}\n"

      # 各維度結果
      [Dimension::FOUNDATIONS, Dimension::STRUCTURAL,
       Dimension::INFERENCE, Dimension::SCIENTIFIC].each do |dim|
        dim_results = @results.select { |r| r.dimension == dim }
        next if dim_results.empty?

        lines << "\n## #{dim}"
        dim_results.each do |r|
          line = "- #{r.severity} #{r.message}"
          line += " [Principle #{r.principle}]" if r.principle
          line += " [Case: #{r.case_study}]" if r.case_study
          lines << line
          if r.evidence
            ev = r.evidence.length > 80 ? "#{r.evidence[0..80]}..." : r.evidence
            lines << "  > `#{ev}`"
          end
        end
      end

      lines.join("\n")
    end
  end

  # 案例模板
  class CaseTemplate
    attr_reader :name, :dimension, :description, :patterns, :principle_violated, :is_zombie_candidate

    def initialize(name:, dimension:, description:, patterns:, principle_violated:, is_zombie_candidate: false)
      @name = name
      @dimension = dimension
      @description = description
      @patterns = patterns
      @principle_violated = principle_violated
      @is_zombie_candidate = is_zombie_candidate
    end
  end

  # 主驗證器
  class Validator
    # Principle I: 偵測隱含假設 (Axiom Smuggling)
    PRINCIPLE_I_PATTERNS = [
      [/\b(obviously|clearly|naturally|of course)\b/i, "隱含未證明假設", Severity::WARNING],
      [/\b(everyone knows|it is known that|as we know)\b/i, "訴諸眾人", Severity::WARNING],
      [/\b(must|always|never|impossible)\b(?!.*\b(if|when|unless)\b)/i, "絕對性陳述缺乏條件", Severity::WARNING],
      [/\b(proves?|confirms?|demonstrates?)\s+that\b/i, "強斷言缺乏證據支持", Severity::WARNING]
    ].freeze

    # Principle II: 偵測結構斷裂 (Isomorphism Breaking)
    PRINCIPLE_II_PATTERNS = [
      [/\b(therefore|thus|hence|so)\b(?!.*\bbecause\b)/i, "推論缺乏因果連結", Severity::WARNING],
      [/\b(this (shows|proves|means))\b(?!.*\b(since|as|because)\b)/i, "結論跳躍", Severity::WARNING],
      [/\b(A|X|this)\s+(is|equals?|means?)\s+(B|Y|that)\b(?!.*\bdefin)/i, "等價宣稱缺乏證明", Severity::WARNING]
    ].freeze

    # Principle III: 偵測推理斷層 (Lossless Logic)
    PRINCIPLE_III_PATTERNS = [
      [/\b(some|many|most|few)\s+\w+\s+(are|is|have|has)\b(?!.*\d+%)/i, "模糊量詞缺乏數據", Severity::WARNING],
      [/\b(likely|probably|possibly|maybe)\b(?!.*\d+%|\bprobability\b)/i, "機率語言缺乏量化", Severity::WARNING],
      [/\band so on\b|\betc\.?\b|\b\.{3}\b/i, "省略可能隱藏關鍵資訊", Severity::WARNING]
    ].freeze

    # Dimension IV: 科學誠信 (可證偽性)
    SCIENTIFIC_PATTERNS = [
      [/\b(cannot be (tested|verified|falsified))\b/i, "不可證偽聲明", Severity::FAIL],
      [/\b(in principle|theoretically)\s+(correct|valid|true)\b/i, "理論正確但實證不明", Severity::WARNING],
      [/\b(self[- ]evident|axiom|postulate)\b(?!.*\bdef)/i, "自明性宣稱", Severity::WARNING]
    ].freeze

    # 案例模板
    CASE_TEMPLATES = [
      CaseTemplate.new(
        name: "Priming (Hidden Variable)",
        dimension: Dimension::FOUNDATIONS,
        description: "隱藏變量導致虛假因果關係",
        patterns: [
          /\b(correlat|associat)\w*\b.*\b(caus|lead|result)\w*\b/i,
          /\b(proves?|shows?|demonstrates?)\b.*\b(because|due to)\b/i
        ],
        principle_violated: "I",
        is_zombie_candidate: true
      ),
      CaseTemplate.new(
        name: "DSGE (Parameter Smuggling)",
        dimension: Dimension::FOUNDATIONS,
        description: "偷渡強假設（如理性預期）",
        patterns: [
          /\b(rational|optimal|efficient)\s+(agent|actor|user|player)\b/i,
          /\b(equilibrium|steady.?state)\b(?!.*\b(if|when|assuming)\b)/i
        ],
        principle_violated: "I"
      ),
      CaseTemplate.new(
        name: "String Theory (Borderline)",
        dimension: Dimension::SCIENTIFIC,
        description: "數學優雅但可證偽性存疑",
        patterns: [
          /\b(elegant|beautiful|symmetric)\s+(solution|theory|model)\b/i,
          /\b(in principle|theoretically)\s+(possible|valid)\b/i
        ],
        principle_violated: "III",
        is_zombie_candidate: true
      ),
      CaseTemplate.new(
        name: "Circular Definition",
        dimension: Dimension::INFERENCE,
        description: "循環定義",
        patterns: [
          /\bX\s+is\s+defined\s+as\s+.*X\b/i,
          /\bbecause\s+it\s+(is|was)\b.*\bso\s+it\s+(is|was)\b/i
        ],
        principle_violated: "II"
      )
    ].freeze

    def initialize(tau: 0.5)
      @tau = tau  # DOA 閾值
    end

    def validate(content, context: {})
      report = ValidationReport.new(content_name: context[:name] || "Unknown")

      # 執行四維度檢查
      report.results.concat(check_dim_i_foundations(content))
      report.results.concat(check_dim_ii_structural(content))
      report.results.concat(check_dim_iii_inference(content))
      report.results.concat(check_dim_iv_scientific(content))
      report.results.concat(match_case_studies(content))

      # 計算分數
      report.score_mvt = calculate_score(report)

      # 判斷 Zombie/Nullity
      determine_status(report)

      report
    end

    private

    def check_dim_i_foundations(content)
      check_patterns(content, PRINCIPLE_I_PATTERNS, Dimension::FOUNDATIONS, "I")
    end

    def check_dim_ii_structural(content)
      check_patterns(content, PRINCIPLE_II_PATTERNS, Dimension::STRUCTURAL, "II")
    end

    def check_dim_iii_inference(content)
      check_patterns(content, PRINCIPLE_III_PATTERNS, Dimension::INFERENCE, "III")
    end

    def check_dim_iv_scientific(content)
      check_patterns(content, SCIENTIFIC_PATTERNS, Dimension::SCIENTIFIC, nil)
    end

    def check_patterns(content, patterns, dimension, principle)
      results = []
      patterns.each do |pattern, message, severity|
        matches = content.scan(pattern)
        matches.each do |match|
          evidence = match.is_a?(Array) ? match.join(" ") : match.to_s
          results << CheckResult.new(
            dimension: dimension,
            severity: severity,
            message: message,
            evidence: evidence,
            principle: principle
          )
        end
      end
      results
    end

    def match_case_studies(content)
      results = []
      CASE_TEMPLATES.each do |template|
        template.patterns.each do |pattern|
          if content.match?(pattern)
            results << CheckResult.new(
              dimension: template.dimension,
              severity: template.is_zombie_candidate ? Severity::ZOMBIE : Severity::WARNING,
              message: template.description,
              case_study: template.name,
              principle: template.principle_violated
            )
            break  # 每個模板只報告一次
          end
        end
      end
      results
    end

    def calculate_score(report)
      # 沒有發現任何問題 = 完美分數
      return 1.0 if report.results.empty?

      total = report.results.size
      weights = {
        Severity::PASS => 1.0,
        Severity::WARNING => 0.7,
        Severity::ZOMBIE => 0.3,
        Severity::FAIL => 0.0,
        Severity::NULLITY => 0.0
      }

      # 計算違規嚴重程度
      fail_count = report.results.count { |r| r.severity == Severity::FAIL }
      warning_count = report.results.count { |r| r.severity == Severity::WARNING }
      zombie_count = report.results.count { |r| r.severity == Severity::ZOMBIE }

      # 基礎分 1.0，根據違規扣分
      score = 1.0
      score -= fail_count * 0.3      # 嚴重違規扣 0.3
      score -= warning_count * 0.1   # 警告扣 0.1
      score -= zombie_count * 0.15   # Zombie 扣 0.15

      [score, 0.0].max
    end

    def determine_status(report)
      fail_count = report.results.count { |r| r.severity == Severity::FAIL }
      zombie_count = report.results.count { |r| r.severity == Severity::ZOMBIE }

      if fail_count >= 3 || report.score_mvt < 0.2
        report.is_nullity = true
      elsif zombie_count > 0 && report.score_mvt >= @tau
        report.is_zombie = true
      end
    end
  end

  # Fail-Fast 閘道
  class FailFastGate
    def initialize(tau: 0.5)
      @validator = Validator.new(tau: tau)
      @tau = tau
    end

    def check(content, context: {})
      report = @validator.validate(content, context: context)

      # 早期拒絕
      if report.is_nullity
        return [false, report]
      end

      if report.score_mvt < @tau && !report.is_zombie
        return [false, report]
      end

      [report.viable?, report]
    end
  end
end

# 使用範例（可刪除）
if __FILE__ == $PROGRAM_NAME
  sample_content = <<~CONTENT
    Obviously, this product will increase your productivity.
    It has been proven that users love this feature.
    The correlation between usage and satisfaction demonstrates that our approach causes success.
    In principle, this solution is theoretically valid for all use cases.
  CONTENT

  validator = Mvt::Validator.new
  report = validator.validate(sample_content, context: { name: "Sample Product" })
  puts report.summary
end
