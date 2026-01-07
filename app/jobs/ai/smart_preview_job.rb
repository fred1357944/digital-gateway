# frozen_string_literal: true

module Ai
  # 非同步生成智慧預覽
  # 使用 SolidQueue/Sidekiq 執行，避免阻塞 Web Request
  class SmartPreviewJob < ApplicationJob
    queue_as :ai_processing

    # 限制重試次數
    retry_on GeminiClient::ApiError, wait: :polynomially_longer, attempts: 3

    # 超時放棄
    discard_on ActiveJob::DeserializationError

    def perform(product_id, api_key: nil)
      product = Product.find(product_id)

      # 檢查是否已有新鮮的 AI 資料（24小時內）
      if product.ai_enhanced? && product.ai_generated_at && product.ai_generated_at > 24.hours.ago
        Rails.logger.info "[SmartPreviewJob] Product #{product_id} has fresh AI data, skipping"
        return
      end

      result = SmartPreview.new(product, api_key: api_key).generate

      if result[:success]
        Rails.logger.info "[SmartPreviewJob] Generated preview for Product #{product_id}"

        # 廣播 Turbo Stream 更新（如果用戶在線）
        broadcast_update(product)
      else
        Rails.logger.error "[SmartPreviewJob] Failed for Product #{product_id}: #{result[:error]}"
      end
    end

    private

    def broadcast_update(product)
      Turbo::StreamsChannel.broadcast_replace_to(
        "product_#{product.id}",
        target: "ai-preview-#{product.id}",
        partial: "ai/previews/preview",
        locals: { product: product }
      )
    end
  end
end
