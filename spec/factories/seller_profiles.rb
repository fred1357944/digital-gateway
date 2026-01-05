FactoryBot.define do
  factory :seller_profile do
    user { nil }
    status { 1 }
    store_name { "MyString" }
    description { "MyText" }
    discarded_at { "2026-01-05 13:49:39" }
  end
end
