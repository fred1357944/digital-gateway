# frozen_string_literal: true

module Optimization
  # Calculates Pareto optimal set from a collection of products
  # Inspired by Jellyfish_Pro3.0 multi-objective optimization
  #
  # A product is Pareto optimal if no other product is better in ALL objectives
  # This creates a "frontier" of non-dominated solutions
  class ParetoFront
    attr_reader :products, :objectives

    DEFAULT_OBJECTIVES = %i[price quality speed reputation relevance].freeze

    def initialize(products, objectives: DEFAULT_OBJECTIVES)
      @products = products.to_a
      @objectives = objectives
    end

    # Compute the Pareto front (non-dominated set)
    # Returns products that are Pareto optimal
    def compute
      return [] if products.empty?

      # Ensure all products have scores
      products_with_scores = products.select { |p| p.product_score.present? }
      return [] if products_with_scores.empty?

      pareto_set = []

      products_with_scores.each do |candidate|
        # Check if candidate is dominated by any in current pareto set
        dominated = pareto_set.any? { |p| dominates?(p, candidate) }
        next if dominated

        # Remove any in pareto set that are dominated by candidate
        pareto_set.reject! { |p| dominates?(candidate, p) }

        # Add candidate to pareto set
        pareto_set << candidate
      end

      pareto_set
    end

    # Compute with rankings - returns all products sorted by Pareto rank
    # Rank 0 = Pareto front, Rank 1 = front after removing rank 0, etc.
    def compute_with_ranks
      remaining = products.select { |p| p.product_score.present? }
      ranked = []
      rank = 0

      while remaining.any?
        front = ParetoFront.new(remaining, objectives: objectives).compute
        front.each { |p| ranked << { product: p, rank: rank } }
        remaining -= front
        rank += 1
      end

      ranked
    end

    # Check if product_a dominates product_b
    # A dominates B if A is >= B in all objectives and > B in at least one
    def dominates?(product_a, product_b)
      score_a = product_a.product_score
      score_b = product_b.product_score

      return false unless score_a && score_b

      all_greater_or_equal = objectives.all? do |obj|
        score_a.score(obj) >= score_b.score(obj)
      end

      at_least_one_greater = objectives.any? do |obj|
        score_a.score(obj) > score_b.score(obj)
      end

      all_greater_or_equal && at_least_one_greater
    end

    # Calculate crowding distance for diversity preservation
    # Higher distance = more isolated solution = more valuable for diversity
    def crowding_distance(pareto_set)
      return {} if pareto_set.size <= 2

      distances = pareto_set.index_with { 0.0 }

      objectives.each do |obj|
        sorted = pareto_set.sort_by { |p| p.product_score.score(obj) }

        # Boundary points get infinite distance
        distances[sorted.first] = Float::INFINITY
        distances[sorted.last] = Float::INFINITY

        # Calculate distance for middle points
        range = sorted.last.product_score.score(obj) - sorted.first.product_score.score(obj)
        next if range.zero?

        (1...sorted.size - 1).each do |i|
          prev_score = sorted[i - 1].product_score.score(obj)
          next_score = sorted[i + 1].product_score.score(obj)
          distances[sorted[i]] += (next_score - prev_score) / range
        end
      end

      distances
    end

    # Select top N diverse solutions from Pareto front
    def select_diverse(n)
      front = compute
      return front if front.size <= n

      distances = crowding_distance(front)
      front.sort_by { |p| -distances[p] }.first(n)
    end

    # Categorize Pareto front members by their strengths
    def categorize
      front = compute
      return {} if front.empty?

      categories = {}

      objectives.each do |obj|
        best = front.max_by { |p| p.product_score.score(obj) }
        categories[obj] = {
          product: best,
          label: objective_label(obj),
          score: best.product_score.score(obj)
        }
      end

      # Find most balanced (highest minimum score)
      balanced = front.max_by do |p|
        objectives.map { |obj| p.product_score.score(obj) }.min
      end
      categories[:balanced] = {
        product: balanced,
        label: "最均衡",
        score: objectives.sum { |obj| balanced.product_score.score(obj) } / objectives.size
      }

      categories
    end

    private

    def objective_label(objective)
      {
        price: "最高CP值",
        quality: "最高品質",
        speed: "最快交付",
        reputation: "信譽最佳",
        relevance: "最相關"
      }[objective] || objective.to_s
    end
  end
end
