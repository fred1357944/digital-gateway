# frozen_string_literal: true

class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def update
    if current_user.update(user_params)
      redirect_to settings_path, notice: "設定已更新"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:gemini_api_key)
  end
end
