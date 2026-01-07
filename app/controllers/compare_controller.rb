# frozen_string_literal: true

# Smart Commerce: Product comparison with Pareto optimization
class CompareController < ApplicationController
  before_action :load_products, only: %i[index show]

  # GET /compare?ids=1,2,3
  def index
    if @products.any?
      ensure_product_scores
      @pareto_front = Optimization::ParetoFront.new(@products)
      @categories = @pareto_front.categorize
    end
  end

  # GET /compare/:id
  def show
    @product = Product.includes(:product_score, :seller_profile).find(params[:id])
    ensure_score_for(@product)

    # Find similar products for comparison
    @similar = Product.active
                      .where.not(id: @product.id)
                      .limit(4)
                      .includes(:product_score, :seller_profile)

    @similar.each { |p| ensure_score_for(p) }
    @products = [@product] + @similar.to_a
  end

  # GET /compare/pareto
  # Show Pareto optimal products
  def pareto
    @pagy, products = paginate(Product.active.includes(:product_score, :seller_profile), limit: 20)

    products.each { |p| ensure_score_for(p) }

    @pareto_front = Optimization::ParetoFront.new(products.select { |p| p.product_score })
    @pareto_products = @pareto_front.compute
    @categories = @pareto_front.categorize

    # State estimation for personalized recommendations
    if current_user
      @state_estimator = Optimization::StateEstimator.new(current_user)
      @state_info = @state_estimator.state_info
    end
  end

  private

  def load_products
    ids = params[:ids].to_s.split(",").map(&:to_i).reject(&:zero?)

    @products = if ids.any?
                  Product.where(id: ids)
                         .includes(:product_score, :seller_profile)
                         .limit(5)
    else
                  Product.active
                         .includes(:product_score, :seller_profile)
                         .limit(5)
    end
  end

  def ensure_product_scores
    @products.each { |p| ensure_score_for(p) }
  end

  def ensure_score_for(product)
    return if product.product_score.present?

    # Create score if not exists (for demo purposes)
    score = product.build_product_score
    score.recalculate!
  end
end
