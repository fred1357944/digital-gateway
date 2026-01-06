FactoryBot.define do
  factory :product do
    association :seller_profile, :verified
    sequence(:title) { |n| "Test Product #{n}" }
    description { "A great digital product for testing." }
    price { 99.0 }
    content_url { "https://example.com/content.pdf" }
    status { :draft }

    trait :published do
      status { :published }
    end

    trait :pending_review do
      status { :pending_review }
    end

    trait :rejected do
      status { :rejected }
    end

    trait :with_mvt_report do
      after(:create) do |product|
        create(:mvt_report, product: product)
      end
    end
  end
end
