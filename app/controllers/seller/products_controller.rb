# frozen_string_literal: true

module Seller
  class ProductsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_seller!
    before_action :set_product, only: %i[show edit update destroy submit_review]

    def index
      @products = current_seller_profile.products.kept.order(created_at: :desc)
    end

    def show
    end

    def new
      @product = current_seller_profile.products.build
    end

    def create
      @product = current_seller_profile.products.build(product_params)

      if @product.save
        redirect_to seller_product_path(@product), notice: "商品已建立"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @product.update(product_params)
        redirect_to seller_product_path(@product), notice: "商品已更新"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.discard
      redirect_to seller_products_path, notice: "商品已刪除"
    end

    def submit_review
      if @product.may_submit_for_review?
        @product.submit_for_review!
        redirect_to seller_product_path(@product), notice: "商品已提交審核，MVT 驗證中..."
      else
        redirect_to seller_product_path(@product), alert: "無法提交審核"
      end
    end

    private

    def set_product
      @product = current_seller_profile.products.kept.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:title, :description, :price, :content_url, :preview_url)
    end

    def ensure_seller!
      unless current_user.seller? && seller_active?
        message = if current_seller_profile&.suspended?
                    "您的賣家帳號已被停權"
                  elsif current_seller_profile&.pending?
                    "您的賣家帳號尚在審核中"
                  else
                    "需要賣家權限"
                  end
        redirect_to root_path, alert: message
      end
    end

    def seller_active?
      current_seller_profile&.verified? && !current_seller_profile&.suspended?
    end

    def current_seller_profile
      @current_seller_profile ||= current_user.seller_profile
    end
    helper_method :current_seller_profile
  end
end
