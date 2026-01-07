# frozen_string_literal: true

class CreateAiConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_conversations do |t|
      t.references :user, null: true, foreign_key: true
      t.string :session_id, null: false, index: true

      # Slot Filling 狀態
      t.jsonb :slots, default: {}, null: false
      t.jsonb :missing_slots, default: [], null: false
      t.string :state, default: "gathering", null: false

      # 對話歷史 (Summary + Sliding Window)
      t.text :context_summary
      t.jsonb :recent_messages, default: [], null: false

      # 追蹤資訊
      t.string :last_query
      t.jsonb :last_result, default: {}
      t.integer :turn_count, default: 0, null: false

      # 成本追蹤
      t.integer :total_input_tokens, default: 0
      t.integer :total_output_tokens, default: 0
      t.decimal :estimated_cost_usd, precision: 10, scale: 6, default: 0

      t.timestamps
    end

    add_index :ai_conversations, :state
    add_index :ai_conversations, :created_at
  end
end
