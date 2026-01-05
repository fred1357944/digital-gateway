FactoryBot.define do
  factory :order do
    user { nil }
    product { nil }
    status { 1 }
    total_amount { "9.99" }
    merchant_trade_no { "MyString" }
    ecpay_trade_no { "MyString" }
  end
end
