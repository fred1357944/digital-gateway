# frozen_string_literal: true

# Stores multi-objective optimization scores for products
# Used for Pareto front calculation and radar chart visualization
class ProductScore < ApplicationRecord
  belongs_to :product

  OBJECTIVES = %i[price quality speed reputation relevance].freeze

  validates :price_score, :quality_score, :speed_score,
            :reputation_score, :relevance_score,
            numericality: { in: 0..100 }

  # Get score for a specific objective
  def score(objective)
    send("#{objective}_score")
  end

  # Get all scores as a hash
  def scores
    OBJECTIVES.index_with { |obj| score(obj) }
  end

  # Calculate weighted total score
  def weighted_total(weights = {})
    default_weights = {
      price: 0.2,
      quality: 0.3,
      speed: 0.15,
      reputation: 0.2,
      relevance: 0.15
    }
    w = default_weights.merge(weights)

    OBJECTIVES.sum { |obj| score(obj) * w[obj] }
  end

  # Check if this product is dominated by another
  # A dominates B if A is >= B in all objectives and > B in at least one
  def dominated_by?(other)
    dominated_count = 0
    strictly_dominated = false

    OBJECTIVES.each do |obj|
      other_score = other.score(obj)
      self_score = score(obj)

      return false if self_score > other_score # Not dominated if better in any

      dominated_count += 1 if other_score >= self_score
      strictly_dominated = true if other_score > self_score
    end

    dominated_count == OBJECTIVES.size && strictly_dominated
  end

  # Recalculate scores based on product data
  def recalculate!
    self.price_score = calculate_price_score
    self.quality_score = calculate_quality_score
    self.speed_score = calculate_speed_score
    self.reputation_score = calculate_reputation_score
    self.relevance_score = 50 # Base score, adjusted by search context
    self.calculated_at = Time.current
    save!
  end

  private

  def calculate_price_score
    # Price competitiveness: lower price = higher score
    # Compare against category average
    return 50 unless product.price.present?

    avg_price = Product.active.where.not(price: nil).average(:price) || product.price
    return 50 if avg_price.zero?

    ratio = product.price / avg_price
    # Map ratio to score: 0.5x = 100, 1x = 75, 2x = 25
    score = (125 - (ratio * 50)).clamp(0, 100).to_i
    score
  end

  def calculate_quality_score
    # For MVP: use random score with slight variation
    # Future: based on reviews, return rate, etc.
    rand(60..90)
  end

  def calculate_speed_score
    # For MVP: based on seller verification status
    seller = product.seller_profile
    return 50 unless seller

    seller.verified? ? rand(70..95) : rand(40..70)
  end

  def calculate_reputation_score
    # Based on seller profile reputation
    seller = product.seller_profile
    return 50 unless seller

    seller.verified? ? rand(75..95) : rand(50..75)
  end
end
