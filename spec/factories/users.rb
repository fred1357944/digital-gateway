FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    role { :buyer }

    trait :seller do
      role { :seller }
      after(:create) do |user|
        create(:seller_profile, :verified, user: user)
      end
    end

    trait :admin do
      role { :admin }
    end
  end
end
