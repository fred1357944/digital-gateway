FactoryBot.define do
  factory :order do
    user
    association :product, :published
    status { :pending }
    amount { 99.0 }

    trait :paid do
      status { :paid }
    end

    trait :expired do
      status { :expired }
    end

    trait :refunded do
      status { :refunded }
    end
  end
end
