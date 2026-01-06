# frozen_string_literal: true

class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: %i[show download]

  def index
    @orders = current_user.orders.includes(:product).order(created_at: :desc)
  end

  def show
  end

  def create
    product = Product.kept.published.find(params[:product_id])

    # Check if user already purchased this product
    existing_order = current_user.orders.where(product: product).where.not(status: :expired).first
    if existing_order
      redirect_to order_path(existing_order), notice: "您已經購買過此商品"
      return
    end

    @order = current_user.orders.build(
      product: product,
      amount: product.price,
      status: :pending
    )

    if @order.save
      # For MVP: Auto-confirm payment (simulate successful payment)
      # In production, redirect to ECPay payment page
      @order.pay!
      redirect_to order_path(@order), notice: "購買成功！您現在可以下載內容。"
    else
      redirect_to product_path(product), alert: "購買失敗：#{@order.errors.full_messages.join(', ')}"
    end
  end

  def download
    unless @order.paid?
      redirect_to order_path(@order), alert: "訂單尚未完成付款"
      return
    end

    # Get or create access token
    access_token = @order.access_token || @order.create_access_token!

    if access_token.valid_for_use?
      # Redirect to content URL with signed token
      redirect_to @order.product.content_url, allow_other_host: true
    else
      redirect_to order_path(@order), alert: "存取連結已過期，請聯繫客服"
    end
  end

  private

  def set_order
    @order = current_user.orders.find(params[:id])
  end
end
