# frozen_string_literal: true

module Ai
  # 購買決策助手 API
  class DecisionsController < ApplicationController
    before_action :set_product

    # POST /ai/products/:product_id/decision
    def create
      api_key = current_user&.gemini_api_key

      unless api_key.present? || ENV["GEMINI_API_KEY"].present?
        return render_error("請先設定 Gemini API Key 才能使用 AI 分析")
      end

      user_context = {
        goal: params[:goal],
        level: params[:level],
        available_hours: params[:available_hours]
      }

      result = ::Ai::DecisionAssistant.new(
        @product,
        user_context: user_context,
        api_key: api_key
      ).analyze

      if result[:success]
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "decision-result",
              partial: "ai/decisions/result",
              locals: { result: result, product: @product }
            )
          end
          format.json { render json: result }
        end
      else
        render_error(result[:error])
      end
    end

    private

    def set_product
      @product = Product.kept.published.find(params[:product_id])
    rescue ActiveRecord::RecordNotFound
      render_error("找不到商品")
    end

    def render_error(message)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "decision-result",
            html: "<div class='p-4 bg-red-50 text-red-600 rounded-lg'>#{message}</div>"
          )
        end
        format.json { render json: { success: false, error: message }, status: :unprocessable_entity }
      end
    end
  end
end
