# frozen_string_literal: true

module Ai
  module Tools
    # 搜尋工具 - 根據關鍵字和篩選條件搜尋商品
    class SearchTool < BaseTool
      def execute(config)
        log "執行搜尋: #{config[:keywords]&.join(', ')}"

        scope = Product.kept.published.includes(:seller_profile, :product_score)

        # 關鍵字搜尋
        if config[:keywords]&.any?
          keyword_conditions = config[:keywords].map { "title ILIKE ? OR description ILIKE ?" }
          keyword_values = config[:keywords].flat_map { |k| ["%#{k}%", "%#{k}%"] }
          scope = scope.where(keyword_conditions.join(" OR "), *keyword_values)
        end

        # 篩選條件
        filters = config[:filters] || {}
        scope = scope.where("price <= ?", filters[:price_max]) if filters[:price_max]

        # 取得結果
        products = scope.limit(config[:limit] || 20)

        {
          success: true,
          products: products.map { |p| serialize_product(p) },
          count: products.size,
          query_summary: config[:user_need]
        }
      rescue StandardError => e
        { success: false, error: e.message }
      end

      private

      def serialize_product(product)
        {
          id: product.id,
          title: product.title,
          price: product.price.to_f,
          description: product.description&.truncate(100),
          ai_enhanced: product.ai_enhanced?,
          seller: product.seller_profile&.store_name,
          score: product.product_score&.quality_score
        }
      end
    end
  end
end
