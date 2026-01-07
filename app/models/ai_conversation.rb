# frozen_string_literal: true

# AI 對話追蹤
#
# 使用 Slot Filling + Summary/Sliding Window 模式
# 儲存多輪對話上下文，支援需求探索功能
#
class AiConversation < ApplicationRecord
  belongs_to :user, optional: true

  # 對話狀態機
  STATES = %w[gathering confirming searching completed].freeze

  # Slot 定義
  REQUIRED_SLOTS = %w[topic].freeze
  OPTIONAL_SLOTS = %w[budget_max level learning_goal time_commitment].freeze
  ALL_SLOTS = (REQUIRED_SLOTS + OPTIONAL_SLOTS).freeze

  # Sliding Window 設定
  MAX_RECENT_MESSAGES = 5

  # Validations
  validates :session_id, presence: true
  validates :state, inclusion: { in: STATES }

  # Scopes
  scope :active, -> { where(state: %w[gathering confirming searching]) }
  scope :for_session, ->(sid) { where(session_id: sid) }
  scope :recent, -> { order(updated_at: :desc) }

  # 從 session 或建立新對話
  def self.find_or_create_for_session(session_id, user: nil)
    conversation = for_session(session_id).active.recent.first
    return conversation if conversation

    create!(
      session_id: session_id,
      user: user,
      state: "gathering"
    )
  end

  # 更新 slots
  def update_slots(new_slots)
    merged = slots.merge(new_slots.stringify_keys.compact)
    update!(
      slots: merged,
      missing_slots: calculate_missing_slots(merged)
    )
  end

  # 檢查必要 slots 是否完整
  def slots_complete?
    missing_slots.empty? || (missing_slots - OPTIONAL_SLOTS.map(&:to_s)).empty?
  end

  # 取得缺少的必要 slots
  def missing_required_slots
    REQUIRED_SLOTS - slots.keys.map(&:to_s)
  end

  # 新增訊息到 sliding window
  def add_message(role:, content:)
    messages = recent_messages.dup
    messages << { role: role, content: content, at: Time.current.iso8601 }

    # 超過上限時，壓縮舊訊息到 summary
    if messages.size > MAX_RECENT_MESSAGES
      compress_old_messages(messages)
    else
      update!(recent_messages: messages)
    end

    increment!(:turn_count)
  end

  # 取得完整上下文（給 LLM 用）
  def full_context
    parts = []
    parts << "[對話摘要]\n#{context_summary}" if context_summary.present?
    parts << "[近期對話]\n#{format_recent_messages}" if recent_messages.any?
    parts << "[已知資訊]\n#{format_slots}" if slots.any?
    parts.join("\n\n")
  end

  # 標記完成
  def complete!(result = {})
    update!(
      state: "completed",
      last_result: result
    )
  end

  # 追蹤 token 使用量
  def track_usage(input_tokens:, output_tokens:, cost_usd: nil)
    self.total_input_tokens += input_tokens
    self.total_output_tokens += output_tokens
    self.estimated_cost_usd += cost_usd if cost_usd
    save!
  end

  private

  def calculate_missing_slots(current_slots)
    ALL_SLOTS - current_slots.keys.map(&:to_s)
  end

  def compress_old_messages(messages)
    # 保留最後 MAX_RECENT_MESSAGES 條
    old_messages = messages[0...-MAX_RECENT_MESSAGES]
    new_recent = messages[-MAX_RECENT_MESSAGES..]

    # 簡單壓縮：把舊訊息加到 summary
    old_summary = context_summary || ""
    new_summary = old_summary + "\n" + old_messages.map do |m|
      "[#{m[:role]}] #{m[:content]}"
    end.join("\n")

    update!(
      context_summary: new_summary.strip,
      recent_messages: new_recent
    )
  end

  def format_recent_messages
    recent_messages.map do |m|
      role_label = m["role"] == "user" ? "用戶" : "AI"
      "#{role_label}: #{m['content']}"
    end.join("\n")
  end

  def format_slots
    slots.map { |k, v| "- #{slot_label(k)}: #{v}" }.join("\n")
  end

  def slot_label(key)
    {
      "topic" => "主題",
      "budget_max" => "預算上限",
      "level" => "難度",
      "learning_goal" => "學習目標",
      "time_commitment" => "時間投入"
    }[key.to_s] || key
  end
end
