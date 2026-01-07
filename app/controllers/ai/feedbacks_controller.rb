# frozen_string_literal: true

module Ai
  # AI 反饋控制器
  # 處理用戶對 AI 回應的 👍/👎 評價
  class FeedbacksController < ApplicationController
    before_action :authenticate_user!

    # POST /ai/feedbacks
    def create
      @feedback = current_user.ai_feedbacks.build(feedback_params)

      if @feedback.save
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("feedback-#{feedback_key}", partial: "ai/feedbacks/thank_you") }
          format.json { render json: { success: true, message: "感謝你的反饋！" } }
        end
      else
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("feedback-#{feedback_key}", partial: "ai/feedbacks/error") }
          format.json { render json: { success: false, errors: @feedback.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    private

    def feedback_params
      params.require(:ai_feedback).permit(
        :feedback_type,
        :reason,
        :query,
        :response_summary,
        :ai_conversation_id,
        :product_id
      )
    end

    def feedback_key
      params.dig(:ai_feedback, :ai_conversation_id) || "new"
    end
  end
end
