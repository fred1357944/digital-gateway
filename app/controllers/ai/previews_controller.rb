# frozen_string_literal: true

module Ai
  # 智慧課程預覽 API
  class PreviewsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_product

    # POST /ai/products/:product_id/preview
    def create
      api_key = current_user.gemini_api_key

      unless api_key.present? || ENV["GEMINI_API_KEY"].present?
        return render_error("請先設定 Gemini API Key")
      end

      result = ::Ai::SmartPreview.new(@product, api_key: api_key).generate

      if result[:success]
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "ai-preview-#{@product.id}",
              partial: "ai/previews/preview",
              locals: { product: @product.reload }
            )
          end
          format.json { render json: { success: true, data: @product.ai_metadata } }
        end
      else
        render_error(result[:error])
      end
    end

    private

    def set_product
      @product = current_user.seller_profile&.products&.find(params[:product_id])

      unless @product
        render_error("找不到商品或無權限")
      end
    end

    def render_error(message)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "ai-preview-#{@product&.id || 'error'}",
            html: "<div class='text-red-600 text-sm'>#{message}</div>"
          )
        end
        format.json { render json: { success: false, error: message }, status: :unprocessable_entity }
      end
    end
  end
end
