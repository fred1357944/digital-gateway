# frozen_string_literal: true

class Product < ApplicationRecord
  include Discard::Model
  include AASM

  belongs_to :seller_profile
  has_many :orders, dependent: :restrict_with_error
  has_one :mvt_report, dependent: :destroy
  has_one :product_score, dependent: :destroy

  # Product status state machine
  aasm column: :status, enum: true do
    state :draft, initial: true
    state :pending_review    # MVT 驗證中
    state :published
    state :rejected

    event :submit_for_review do
      transitions from: :draft, to: :pending_review
      after do
        MvtValidationJob.perform_later(id)
      end
    end

    event :approve do
      transitions from: :pending_review, to: :published
    end

    event :reject do
      transitions from: :pending_review, to: :rejected
    end

    event :unpublish do
      transitions from: :published, to: :draft
    end
  end

  enum :status, { draft: 0, pending_review: 1, published: 2, rejected: 3 }, default: :draft

  # Validations
  validates :title, presence: true, length: { maximum: 200 }
  validates :content_url, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :available, -> { kept.published }
  scope :active, -> { kept.published }  # Alias for smart commerce
  scope :by_seller, ->(seller_profile_id) { where(seller_profile_id: seller_profile_id) }
  scope :with_scores, -> { includes(:product_score).where.not(product_scores: { id: nil }) }

  # Delegate seller info
  delegate :store_name, to: :seller_profile, prefix: true
  delegate :user, to: :seller_profile

  def mvt_viable?
    mvt_report&.viable?
  end

  # AI Metadata accessors
  def ai_summary
    ai_metadata["summary"]
  end

  def ai_target_audience
    ai_metadata["target_audience"] || []
  end

  def ai_outline
    ai_metadata["outline"] || []
  end

  def ai_key_benefits
    ai_metadata["key_benefits"] || []
  end

  def ai_enhanced?
    ai_metadata.present? && ai_metadata["summary"].present?
  end

  def ai_generated_at
    ai_metadata["generated_at"]&.to_datetime
  end

  # Infer content type from URL extension or return default
  def content_type
    return "Digital" unless content_url.present?

    extension = File.extname(content_url).downcase.delete(".")
    case extension
    when "pdf", "epub", "mobi" then "E-book"
    when "mp4", "mov", "webm" then "Video"
    when "mp3", "wav", "m4a" then "Audio"
    when "zip", "rar", "7z" then "Download"
    when "psd", "ai", "sketch", "fig" then "Template"
    else "Digital"
    end
  end
end
