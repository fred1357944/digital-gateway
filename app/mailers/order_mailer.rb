# frozen_string_literal: true

class OrderMailer < ApplicationMailer
  def confirmation(order)
    @order = order
    @user = order.user
    @product = order.product

    mail(
      to: @user.email,
      subject: "Order Confirmed - #{@product.title}"
    )
  end
end
