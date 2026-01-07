# frozen_string_literal: true

module Ai
  module Tools
    # 預覽工具 - 生成商品智慧預覽
    class PreviewTool < BaseTool
      def execute(config)
        product_id = config[:product_id]
        log "生成預覽: Product ##{product_id}"

        product = Product.find_by(id: product_id)
        return { success: false, error: "商品不存在" } unless product

        # 使用現有的 SmartPreview 服務
        preview = Ai::SmartPreview.new(product, api_key: user&.gemini_api_key)
        result = preview.generate

        {
          success: result[:success],
          product_id: product_id,
          preview: result[:preview],
          highlights: result[:highlights]
        }
      rescue StandardError => e
        { success: false, error: e.message }
      end
    end
  end
end
