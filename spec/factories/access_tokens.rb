FactoryBot.define do
  factory :access_token do
    order
    user
    token { SecureRandom.urlsafe_base64(32) }
    expires_at { 30.days.from_now }
    max_uses { 10 }
    use_count { 0 }

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :revoked do
      revoked_at { Time.current }
    end

    trait :exhausted do
      use_count { 10 }
    end
  end
end
