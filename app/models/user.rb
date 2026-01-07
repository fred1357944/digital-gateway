# frozen_string_literal: true

class User < ApplicationRecord
  include Discard::Model

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Roles: buyer (0), seller (1), admin (2)
  enum :role, { buyer: 0, seller: 1, admin: 2 }, default: :buyer

  # BYOK - Encrypt Gemini API Key with Lockbox
  has_encrypted :gemini_api_key

  # Associations
  has_one :seller_profile, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :access_tokens, dependent: :destroy
  has_many :ai_conversations, dependent: :destroy
  has_many :ai_credit_transactions, dependent: :destroy
  has_many :ai_feedbacks, dependent: :destroy

  # Validations
  validates :role, presence: true

  # Callbacks
  after_create :create_seller_profile, if: :seller?

  # Check if user has valid API key for BYOK
  def has_api_key?
    gemini_api_key.present?
  end

  # Alias for views
  alias_method :has_gemini_key?, :has_api_key?

  # ========== AI Credits 管理 ==========

  # 是否使用自己的 API Key (BYOK)
  def byok?
    gemini_api_key.present?
  end

  # 是否有足夠點數
  def has_credits?(amount = 1)
    ai_credits >= amount
  end

  # 扣除點數 (原子操作)
  def deduct_credits!(amount, action_type:, token_usage: {}, conversation: nil, metadata: {})
    return false unless has_credits?(amount)

    transaction do
      decrement!(:ai_credits, amount)
      AiCreditTransaction.record_usage(
        user: self,
        amount: amount,
        action_type: action_type,
        token_usage: token_usage,
        conversation: conversation,
        metadata: metadata
      )
    end
    true
  end

  # 增加點數
  def add_credits!(amount, reason: "top_up")
    transaction do
      increment!(:ai_credits, amount)
      if reason == "top_up"
        AiCreditTransaction.record_top_up(user: self, amount: amount)
      else
        AiCreditTransaction.record_bonus(user: self, amount: amount, reason: reason)
      end
    end
    true
  end

  # 今日使用量
  def today_ai_usage
    ai_credit_transactions.today.credits_used.sum(:amount).abs
  end

  # 本月使用量
  def month_ai_usage
    ai_credit_transactions
      .where("created_at >= ?", Time.current.beginning_of_month)
      .credits_used
      .sum(:amount)
      .abs
  end

  private

  def create_seller_profile
    build_seller_profile.save
  end
end
