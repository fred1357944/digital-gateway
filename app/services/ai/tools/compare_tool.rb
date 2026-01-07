# frozen_string_literal: true

module Ai
  module Tools
    # 比較工具 - 比較多個商品
    class CompareTool < BaseTool
      def execute(config)
        product_ids = config[:product_ids] || []
        log "比較商品: #{product_ids.join(', ')}"

        return { success: false, error: "需要至少 2 個商品進行比較" } if product_ids.size < 2

        products = Product.where(id: product_ids).includes(:product_score, :seller_profile)

        return { success: false, error: "找不到指定商品" } if products.empty?

        # 使用 AI 生成比較分析
        comparison = generate_comparison(products)

        {
          success: true,
          products: products.map { |p| serialize_product(p) },
          comparison: comparison,
          recommendation: comparison[:recommendation]
        }
      rescue StandardError => e
        { success: false, error: e.message }
      end

      private

      def generate_comparison(products)
        product_info = products.map do |p|
          "- #{p.title}: NT$#{p.price.to_i}, 品質分數: #{p.product_score&.quality_score || 'N/A'}"
        end.join("\n")

        prompt = <<~PROMPT
          比較以下商品，給出分析和推薦：

          #{product_info}

          輸出 JSON：
          ```json
          {
            "comparison": [
              { "product": "商品名", "pros": ["優點"], "cons": ["缺點"] }
            ],
            "recommendation": "推薦哪個及原因",
            "best_value": "最高CP值商品"
          }
          ```
        PROMPT

        result = client.analyze_content("", prompt: prompt)
        json_str = result.text.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip
        JSON.parse(json_str, symbolize_names: true)
      rescue JSON::ParserError
        { comparison: [], recommendation: "無法生成比較結果" }
      end

      def serialize_product(product)
        {
          id: product.id,
          title: product.title,
          price: product.price.to_f,
          quality_score: product.product_score&.quality_score,
          seller: product.seller_profile&.store_name
        }
      end
    end
  end
end
