# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ai::SmartPreview do
  let(:seller_profile) { create(:seller_profile) }
  let(:product) do
    create(:product,
           seller_profile: seller_profile,
           title: "Rails 入門教學",
           description: "從零開始學習 Ruby on Rails 框架")
  end

  describe "#generate" do
    context "when API key is available" do
      let(:api_key) { "test-api-key" }
      let(:mock_response) do
        <<~JSON
          {
            "summary": "完整的 Rails 入門課程",
            "key_benefits": ["循序漸進", "實戰導向", "最新版本"],
            "outline": [
              {"chapter": "環境設定", "description": "安裝 Ruby 和 Rails"},
              {"chapter": "MVC 架構", "description": "了解基本架構"}
            ],
            "target_audience": [
              {"type": "適合", "description": "程式新手"},
              {"type": "不適合", "description": "已有 Rails 經驗者"}
            ],
            "difficulty": "入門",
            "estimated_hours": 10
          }
        JSON
      end

      before do
        allow_any_instance_of(GeminiClient).to receive(:analyze_content)
          .and_return(mock_response)
      end

      it "generates AI metadata successfully" do
        result = described_class.new(product, api_key: api_key).generate

        expect(result[:success]).to be true
        expect(product.reload.ai_enhanced?).to be true
        expect(product.ai_summary).to eq("完整的 Rails 入門課程")
        expect(product.ai_key_benefits).to include("循序漸進")
      end
    end

    context "when API call fails" do
      before do
        allow_any_instance_of(GeminiClient).to receive(:analyze_content)
          .and_raise(GeminiClient::ApiError.new("API error"))
      end

      it "returns error response" do
        result = described_class.new(product, api_key: "test").generate

        expect(result[:success]).to be false
        expect(result[:error]).to include("API error")
      end
    end
  end
end
