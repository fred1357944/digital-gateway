class ProductsController < ApplicationController
  def index
    @products = Product.kept.published.includes(:seller_profile).order(created_at: :desc)
  end

  def show
    @product = Product.kept.published.find(params[:id])
  end
end
