# frozen_string_literal: true

module Ai
  # AI 使用量控制器
  class UsageController < ApplicationController
    before_action :authenticate_user!

    # GET /ai/usage
    def show
      @stats = ::Ai::Service.usage_stats(current_user)
      @transactions = current_user.ai_credit_transactions.recent.limit(20)

      respond_to do |format|
        format.html
        format.json { render json: @stats }
      end
    end
  end
end
