# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ai::DecisionAssistant do
  let(:seller_profile) { create(:seller_profile) }
  let(:product) do
    create(:product,
           seller_profile: seller_profile,
           title: "進階 JavaScript 教學",
           description: "深入學習 JavaScript 進階概念")
  end

  let(:user_context) do
    {
      goal: "想學會前端框架",
      level: "有基礎概念",
      available_hours: "5"
    }
  end

  describe "#analyze" do
    context "when API key is available" do
      let(:api_key) { "test-api-key" }
      let(:mock_response) do
        <<~JSON
          {
            "recommendation": "推薦",
            "fit_score": 85,
            "reasons": [
              "課程難度適合有基礎的學習者",
              "內容與學習目標相符"
            ],
            "concerns": [
              "需要先熟悉基本 JavaScript 語法"
            ],
            "alternatives": null,
            "summary": "這門課程非常適合您的學習目標"
          }
        JSON
      end

      before do
        allow_any_instance_of(GeminiClient).to receive(:analyze_content)
          .and_return(mock_response)
      end

      it "analyzes fit successfully" do
        result = described_class.new(
          product,
          user_context: user_context,
          api_key: api_key
        ).analyze

        expect(result[:success]).to be true
        expect(result[:recommendation]).to eq("推薦")
        expect(result[:fit_score]).to eq(85)
        expect(result[:reasons]).to include("課程難度適合有基礎的學習者")
      end
    end

    context "when API call fails" do
      before do
        allow_any_instance_of(GeminiClient).to receive(:analyze_content)
          .and_raise(GeminiClient::ApiError.new("API error"))
      end

      it "returns error response" do
        result = described_class.new(
          product,
          user_context: user_context,
          api_key: "test"
        ).analyze

        expect(result[:success]).to be false
        expect(result[:error]).to include("API error")
      end
    end
  end
end
