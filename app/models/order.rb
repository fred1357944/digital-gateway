# frozen_string_literal: true

class Order < ApplicationRecord
  include AASM

  belongs_to :user
  belongs_to :product
  has_one :access_token, dependent: :destroy

  # Order status state machine
  aasm column: :status, enum: true do
    state :pending, initial: true
    state :paid
    state :expired
    state :refunded

    event :pay do
      transitions from: :pending, to: :paid
      after do
        create_access_token!
        OrderMailer.confirmation(self).deliver_later
      end
    end

    event :expire do
      transitions from: :pending, to: :expired
    end

    event :refund do
      transitions from: :paid, to: :refunded
      after do
        access_token&.revoke!
      end
    end
  end

  enum :status, { pending: 0, paid: 1, expired: 2, refunded: 3 }, default: :pending

  # Callbacks
  before_create :generate_merchant_trade_no
  before_create :set_total_amount

  # Validations
  validates :merchant_trade_no, uniqueness: true, allow_nil: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }

  # Delegate
  delegate :title, :content_url, to: :product, prefix: true

  def create_access_token!
    AccessToken.create!(
      order: self,
      user: user,
      expires_at: 30.days.from_now,
      max_uses: 10
    )
  end

  private

  def generate_merchant_trade_no
    self.merchant_trade_no = "DG#{Time.current.strftime('%Y%m%d%H%M%S')}#{SecureRandom.hex(4).upcase}"
  end

  def set_total_amount
    self.total_amount = product.price
  end
end
