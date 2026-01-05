# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      include Pundit::Authorization

      before_action :authenticate_user!

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from Pundit::NotAuthorizedError, with: :forbidden

      private

      def not_found
        render json: { error: "Not found" }, status: :not_found
      end

      def forbidden
        render json: { error: "Forbidden" }, status: :forbidden
      end

      def authenticate_user!
        # For now, use Devise token auth or session
        # In production, implement JWT or API key auth
        head :unauthorized unless current_user
      end
    end
  end
end
