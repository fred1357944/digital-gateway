# frozen_string_literal: true

class MvtReport < ApplicationRecord
  belongs_to :product

  enum :status, { pass: 0, warning: 1, fail: 2, zombie: 3, nullity: 4 }, default: :pass

  # Check if product passed MVT validation
  def viable?
    %w[pass warning zombie].include?(status)
  end

  def failed?
    %w[fail nullity].include?(status)
  end

  # Parse details JSON
  def results
    details&.dig("results") || []
  end

  def violation_rate
    details&.dig("violation_rate") || 0.0
  end

  def summary
    case status
    when "pass"
      "✓ 通過 MVT 驗證"
    when "warning"
      "⚠ 通過（有警告）"
    when "zombie"
      "🧟 結構有問題但可能有預測價值"
    when "fail"
      "✗ 未通過 MVT 驗證"
    when "nullity"
      "∅ 完全無效"
    end
  end
end
