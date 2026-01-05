FactoryBot.define do
  factory :product do
    seller_profile { nil }
    title { "MyString" }
    description { "MyText" }
    price { "9.99" }
    content_url { "MyString" }
    preview_url { "MyString" }
    status { 1 }
    discarded_at { "2026-01-05 13:49:47" }
  end
end
