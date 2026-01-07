# frozen_string_literal: true

module Ai
  module Tools
    # 評分工具 - 計算商品評分
    class ScoreTool < BaseTool
      WEIGHTS = {
        price: 0.25,
        quality: 0.30,
        relevance: 0.25,
        reputation: 0.20
      }.freeze

      def execute(config)
        product_id = config[:product_id]
        log "計算評分: Product ##{product_id}"

        product = Product.find_by(id: product_id)
        return { success: false, error: "商品不存在" } unless product

        scores = calculate_scores(product)
        weighted_score = calculate_weighted_score(scores)

        {
          success: true,
          product_id: product_id,
          scores: scores,
          weighted_score: weighted_score.round(2),
          grade: score_to_grade(weighted_score)
        }
      rescue StandardError => e
        { success: false, error: e.message }
      end

      private

      def calculate_scores(product)
        {
          price: price_score(product.price),
          quality: product.product_score&.quality_score || 50,
          relevance: product.product_score&.relevance_score || 50,
          reputation: product.seller_profile&.reputation_score || 50
        }
      end

      def price_score(price)
        # 價格越低分數越高（假設 3000 為基準）
        base = 3000.0
        score = ((base - price.to_f) / base * 50) + 50
        [[score, 0].max, 100].min
      end

      def calculate_weighted_score(scores)
        WEIGHTS.sum { |key, weight| scores[key] * weight }
      end

      def score_to_grade(score)
        case score
        when 90..100 then "A+"
        when 80..89 then "A"
        when 70..79 then "B"
        when 60..69 then "C"
        else "D"
        end
      end
    end
  end
end
