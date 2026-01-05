# frozen_string_literal: true

module Api
  module V1
    class ProductsController < BaseController
      skip_before_action :authenticate_user!, only: %i[index show]

      def index
        @products = Product.available
                           .includes(:seller_profile, :mvt_report)
                           .order(created_at: :desc)

        render json: @products.map { |p| product_json(p) }
      end

      def show
        @product = Product.available.find(params[:id])
        render json: product_json(@product, detailed: true)
      end

      private

      def product_json(product, detailed: false)
        json = {
          id: product.id,
          title: product.title,
          price: product.price.to_f,
          seller: product.seller_profile_store_name,
          mvt_status: product.mvt_report&.summary,
          created_at: product.created_at.iso8601
        }

        if detailed
          json.merge!(
            description: product.description,
            preview_url: product.preview_url,
            mvt_score: product.mvt_report&.score&.to_f
          )
        end

        json
      end
    end
  end
end
