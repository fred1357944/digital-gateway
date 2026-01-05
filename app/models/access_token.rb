# frozen_string_literal: true

class AccessToken < ApplicationRecord
  belongs_to :order
  belongs_to :user

  # Callbacks
  before_create :generate_token
  before_create :set_defaults

  # Scopes
  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }

  def valid_token?
    !revoked? && !expired? && !exceeded_uses?
  end

  def expired?
    expires_at < Time.current
  end

  def exceeded_uses?
    use_count >= max_uses
  end

  def revoked?
    revoked_at.present?
  end

  def use!
    return false unless valid_token?

    increment!(:use_count)
    true
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  # Generate signed URL for accessing content
  def signed_url(expires_in: 1.hour)
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)
    payload = {
      token_id: id,
      product_id: order.product_id,
      expires_at: expires_in.from_now.to_i
    }
    verifier.generate(payload, expires_at: expires_in.from_now)
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def set_defaults
    self.expires_at ||= 30.days.from_now
    self.max_uses ||= 10
    self.use_count ||= 0
  end
end
