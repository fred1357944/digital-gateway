# frozen_string_literal: true

module Optimization
  # Evolutionary State Estimation (ESE)
  # Inspired by Jellyfish_Pro3.0's adaptive strategy selection
  #
  # Estimates the current state of user's search journey and suggests
  # appropriate recommendation strategies:
  # - Exploration: Wide search, show diverse options
  # - Exploitation: Deep dive into promising areas
  # - Convergence: Narrow down to final candidates
  # - Stagnation: User stuck, need to break out
  class StateEstimator
    STATES = {
      exploration: {
        description: "探索階段 - 擴大搜索範圍",
        strategy: :diverse,
        suggestion: "嘗試不同類型的商品，找出您的偏好"
      },
      exploitation: {
        description: "開發階段 - 深入優質區域",
        strategy: :focused,
        suggestion: "您似乎對這類商品感興趣，看看更多相似選項"
      },
      convergence: {
        description: "收斂階段 - 鎖定最佳解",
        strategy: :comparison,
        suggestion: "準備做決定了？這些是您的最佳選擇"
      },
      stagnation: {
        description: "停滯階段 - 需要突破",
        strategy: :refresh,
        suggestion: "換個角度看看？試試這些不同的選項"
      }
    }.freeze

    attr_reader :user, :search_histories

    def initialize(user)
      @user = user
      # Gracefully handle missing search_histories association
      @search_histories = if user&.respond_to?(:search_histories)
        user.search_histories&.recent || []
      else
        []
      end
    end

    # Estimate current evolutionary state
    def estimate
      return :exploration if search_histories.empty?

      features = extract_features
      classify_state(features)
    end

    # Get full state info with description and suggestion
    def state_info
      state = estimate
      STATES[state].merge(state: state)
    end

    # Suggest strategy based on state
    def suggested_strategy
      STATES[estimate][:strategy]
    end

    # Get recommendation settings based on state
    def recommendation_settings
      case estimate
      when :exploration
        { diversity_weight: 0.8, relevance_weight: 0.2, limit: 12 }
      when :exploitation
        { diversity_weight: 0.3, relevance_weight: 0.7, limit: 8 }
      when :convergence
        { diversity_weight: 0.1, relevance_weight: 0.9, limit: 5 }
      when :stagnation
        { diversity_weight: 0.9, relevance_weight: 0.1, limit: 10 }
      end
    end

    private

    def extract_features
      return {} if search_histories.empty?

      recent = search_histories.limit(10)

      {
        search_count: recent.size,
        unique_queries: recent.pluck(:query).uniq.size,
        click_rate: calculate_click_rate(recent),
        purchase_made: recent.any? { |h| h.purchased_product_id.present? },
        query_similarity: calculate_query_similarity(recent),
        filter_consistency: calculate_filter_consistency(recent),
        time_between_searches: calculate_time_pattern(recent)
      }
    end

    def classify_state(features)
      # Stagnation: many searches, low clicks, no purchase, similar queries
      if features[:search_count] >= 5 &&
         features[:click_rate] < 0.2 &&
         features[:query_similarity] > 0.7
        return :stagnation
      end

      # Convergence: fewer unique queries, high click rate, consistent filters
      if features[:unique_queries] <= 2 &&
         features[:click_rate] > 0.5 &&
         features[:filter_consistency] > 0.7
        return :convergence
      end

      # Exploitation: moderate variety, decent clicks, focused filters
      if features[:unique_queries] <= 4 &&
         features[:click_rate] > 0.3
        return :exploitation
      end

      # Default: Exploration
      :exploration
    end

    def calculate_click_rate(histories)
      return 0.0 if histories.empty?

      clicked = histories.count { |h| h.clicked_product_ids.present? && h.clicked_product_ids.any? }
      clicked.to_f / histories.size
    end

    def calculate_query_similarity(histories)
      queries = histories.pluck(:query).compact
      return 0.0 if queries.size < 2

      # Simple similarity: % of queries that share common words
      words = queries.map { |q| q.to_s.downcase.split(/\s+/) }
      common_words = words.reduce(:&) || []

      return 0.0 if words.flatten.empty?

      common_words.size.to_f / words.map(&:size).max
    end

    def calculate_filter_consistency(histories)
      filters = histories.pluck(:filters).compact
      return 0.0 if filters.size < 2

      # Check how many searches use same filter keys
      all_keys = filters.map(&:keys).map(&:to_set)
      return 0.0 if all_keys.empty?

      common_keys = all_keys.reduce(:&)
      common_keys.size.to_f / all_keys.map(&:size).max
    end

    def calculate_time_pattern(histories)
      return 0 if histories.size < 2

      times = histories.pluck(:created_at).sort
      intervals = times.each_cons(2).map { |a, b| (b - a).to_i }

      return 0 if intervals.empty?

      intervals.sum / intervals.size # Average seconds between searches
    end
  end
end
