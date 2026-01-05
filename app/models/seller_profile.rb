# frozen_string_literal: true

class SellerProfile < ApplicationRecord
  include Discard::Model
  include AASM

  belongs_to :user
  has_many :products, dependent: :destroy

  # Status state machine
  aasm column: :status, enum: true do
    state :pending, initial: true
    state :verified
    state :suspended

    event :verify do
      transitions from: :pending, to: :verified
    end

    event :suspend do
      transitions from: %i[pending verified], to: :suspended
    end

    event :reactivate do
      transitions from: :suspended, to: :verified
    end
  end

  enum :status, { pending: 0, verified: 1, suspended: 2 }, default: :pending

  validates :store_name, presence: true, length: { maximum: 100 }
end
