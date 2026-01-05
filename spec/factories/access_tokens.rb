FactoryBot.define do
  factory :access_token do
    order { nil }
    user { nil }
    token { "MyString" }
    expires_at { "2026-01-05 13:50:01" }
    max_uses { 1 }
    use_count { 1 }
    revoked_at { "2026-01-05 13:50:01" }
  end
end
