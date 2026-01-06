FactoryBot.define do
  factory :mvt_report do
    product
    score { 0.85 }
    status { :pass }
    details do
      {
        results: [
          { dimension: "foundations", score: 0.9, pass: true },
          { dimension: "structure", score: 0.85, pass: true },
          { dimension: "logic", score: 0.8, pass: true },
          { dimension: "expression", score: 0.85, pass: true }
        ]
      }
    end

    trait :warning do
      status { :warning }
      score { 0.65 }
    end

    trait :fail do
      status { :fail }
      score { 0.3 }
    end
  end
end
