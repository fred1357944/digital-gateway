# frozen_string_literal: true

class CreateAiFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_feedbacks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :ai_conversation, foreign_key: true
      t.references :product, foreign_key: true

      # 反饋類型: thumbs_up, thumbs_down
      t.string :feedback_type, null: false

      # 反饋原因 (可選)
      t.text :reason

      # 原始查詢
      t.text :query

      # AI 回應摘要
      t.text :response_summary

      t.timestamps
    end

    add_index :ai_feedbacks, :feedback_type
    add_index :ai_feedbacks, [:user_id, :created_at]
  end
end
