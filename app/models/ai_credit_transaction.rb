# frozen_string_literal: true

# AI 點數交易記錄
# 追蹤所有 AI 點數的變動（消耗、儲值、贈送）
class AiCreditTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :ai_conversation, optional: true

  # 交易類型
  ACTION_TYPES = %w[
    explore
    search
    compare
    mvt_validation
    smart_preview
    decision_assist
    top_up
    bonus
    refund
  ].freeze

  validates :amount, presence: true
  validates :action_type, presence: true, inclusion: { in: ACTION_TYPES }

  scope :credits_used, -> { where("amount < 0") }
  scope :credits_added, -> { where("amount > 0") }
  scope :by_action, ->(type) { where(action_type: type) }
  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where("created_at >= ?", Time.current.beginning_of_day) }

  # 取得 Token 用量
  def input_tokens
    token_usage["input_tokens"] || 0
  end

  def output_tokens
    token_usage["output_tokens"] || 0
  end

  def total_tokens
    token_usage["total_tokens"] || input_tokens + output_tokens
  end

  # 類別方法：建立扣點記錄
  def self.record_usage(user:, amount:, action_type:, token_usage: {}, conversation: nil, metadata: {})
    create!(
      user: user,
      ai_conversation: conversation,
      amount: -amount.abs, # 確保是負數
      action_type: action_type,
      token_usage: token_usage,
      metadata: metadata
    )
  end

  # 類別方法：建立儲值記錄
  def self.record_top_up(user:, amount:, metadata: {})
    create!(
      user: user,
      amount: amount.abs, # 確保是正數
      action_type: "top_up",
      metadata: metadata
    )
  end

  # 類別方法：建立贈送記錄
  def self.record_bonus(user:, amount:, reason:)
    create!(
      user: user,
      amount: amount.abs,
      action_type: "bonus",
      metadata: { reason: reason }
    )
  end
end
