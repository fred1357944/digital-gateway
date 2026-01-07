# frozen_string_literal: true

module Ai
  module Tools
    # 篩選工具 - 根據條件篩選商品
    class FilterTool < BaseTool
      def execute(config)
        log "執行篩選: #{config[:filters]}"

        scope = Product.kept.published.includes(:seller_profile, :product_score)
        filters = config[:filters] || {}

        # 價格範圍
        scope = scope.where("price >= ?", filters[:price_min]) if filters[:price_min]
        scope = scope.where("price <= ?", filters[:price_max]) if filters[:price_max]

        # AI 增強
        scope = scope.where(ai_enhanced: true) if filters[:ai_enhanced]

        # 排序
        case filters[:sort_by]
        when "price_asc"
          scope = scope.order(price: :asc)
        when "price_desc"
          scope = scope.order(price: :desc)
        when "newest"
          scope = scope.order(created_at: :desc)
        else
          scope = scope.order(created_at: :desc)
        end

        products = scope.limit(config[:limit] || 20)

        {
          success: true,
          products: products.map { |p| serialize_product(p) },
          count: products.size,
          filters_applied: filters
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
          ai_enhanced: product.ai_enhanced?
        }
      end
    end
  end
end
