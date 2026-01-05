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
  encrypts :gemini_api_key, migrating: true

  # Associations
  has_one :seller_profile, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :access_tokens, dependent: :destroy

  # Validations
  validates :role, presence: true

  # Callbacks
  after_create :create_seller_profile, if: :seller?

  # Check if user has valid API key for BYOK
  def has_api_key?
    gemini_api_key.present?
  end

  private

  def create_seller_profile
    build_seller_profile.save
  end
end
