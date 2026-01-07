# frozen_string_literal: true

module AiHelper
  # 交易類型標籤
  def action_type_label(type)
    labels = {
      "explore" => "🔍 探索對話",
      "search" => "🔎 智慧搜尋",
      "compare" => "⚖️ 商品比較",
      "smart_preview" => "👁️ 智慧預覽",
      "decision_assist" => "🤔 購買決策",
      "mvt_validation" => "✅ MVT 驗證",
      "top_up" => "💰 儲值",
      "bonus" => "🎁 贈送",
      "refund" => "↩️ 退款"
    }
    labels[type] || type
  end

  # 點數徽章顏色
  def credits_badge_class(credits)
    if credits <= 0
      "bg-red-100 text-red-600"
    elsif credits < 20
      "bg-yellow-100 text-yellow-700"
    else
      "bg-purple-100 text-purple-600"
    end
  end

  # 點數狀態文字
  def credits_status_text(user)
    if user.byok?
      "🔑 自有 API"
    elsif user.ai_credits <= 0
      "點數不足"
    else
      "#{user.ai_credits} 點"
    end
  end
end
