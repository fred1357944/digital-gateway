# frozen_string_literal: true

# AI 回應反饋
# 追蹤用戶對 AI 推薦的 👍/👎 評價
class AiFeedback < ApplicationRecord
  belongs_to :user
  belongs_to :ai_conversation, optional: true
  belongs_to :product, optional: true

  FEEDBACK_TYPES = %w[thumbs_up thumbs_down].freeze

  validates :feedback_type, presence: true, inclusion: { in: FEEDBACK_TYPES }

  scope :positive, -> { where(feedback_type: "thumbs_up") }
  scope :negative, -> { where(feedback_type: "thumbs_down") }
  scope :recent, -> { order(created_at: :desc) }

  # 用戶的負面反饋（用於 RAG 優化）
  def self.negative_for_user(user)
    where(user: user, feedback_type: "thumbs_down")
      .includes(:product)
      .order(created_at: :desc)
  end

  # 取得用戶不喜歡的產品關鍵字
  def self.disliked_keywords_for(user)
    negative_for_user(user)
      .where.not(product: nil)
      .map { |f| f.product.title.split(/\s+/) }
      .flatten
      .uniq
      .take(10)
  end

  # 正向率
  def self.approval_rate
    total = count
    return 0 if total.zero?

    (positive.count.to_f / total * 100).round(1)
  end
end
