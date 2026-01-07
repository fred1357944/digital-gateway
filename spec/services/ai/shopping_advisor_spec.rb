# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ai::ShoppingAdvisor do
  let(:seller_profile) { create(:seller_profile) }

  before do
    # Create test products
    create(:product,
           seller_profile: seller_profile,
           title: "Rails 入門教學",
           description: "從零開始學習 Ruby on Rails",
           price: 299,
           status: :published)

    create(:product,
           seller_profile: seller_profile,
           title: "進階 Rails 開發",
           description: "深入 Rails 進階技術",
           price: 599,
           status: :published)
  end

  describe "#search" do
    let(:query) { "便宜的 Rails 入門課" }
    let(:api_key) { "test-api-key" }

    let(:mock_intent_response) do
      <<~JSON
        {
          "keywords": ["Rails", "Ruby on Rails"],
          "category": "程式開發",
          "difficulty": "入門",
          "price_max": 500,
          "intent_type": "search",
          "user_need": "學習 Rails 框架基礎"
        }
      JSON
    end

    before do
      allow_any_instance_of(GeminiClient).to receive(:analyze_content)
        .and_return(mock_intent_response)
    end

    it "parses user intent correctly" do
      result = described_class.new(query, api_key: api_key).search

      expect(result[:success]).to be true
      expect(result[:intent][:keywords]).to include("Rails")
      expect(result[:intent][:price_max]).to eq(500)
    end

    it "filters products by price" do
      result = described_class.new(query, api_key: api_key).search

      expect(result[:products].count).to eq(1)
      expect(result[:products].first.title).to include("入門")
    end

    it "returns explanation" do
      result = described_class.new(query, api_key: api_key).search

      expect(result[:explanation]).to include("學習 Rails 框架基礎")
    end
  end

  context "when intent parsing fails" do
    let(:query) { "some query" }

    before do
      allow_any_instance_of(GeminiClient).to receive(:analyze_content)
        .and_return("invalid json")
    end

    it "falls back to keyword search" do
      result = described_class.new(query, api_key: "test").search

      expect(result[:success]).to be true
      expect(result[:intent][:keywords]).to eq(["some", "query"])
    end
  end
end
