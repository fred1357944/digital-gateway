FactoryBot.define do
  factory :seller_profile do
    user
    sequence(:store_name) { |n| "Test Store #{n}" }
    status { :pending }

    trait :verified do
      status { :verified }
    end

    trait :suspended do
      status { :suspended }
    end
  end
end
