# frozen_string_literal: true

class CreateAiCreditTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_credit_transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :ai_conversation, foreign_key: true

      # 交易金額 (負數扣點，正數儲值)
      t.integer :amount, null: false

      # 交易類型
      # explore: 探索模式對話
      # search: 搜尋
      # compare: 比較分析
      # mvt_validation: MVT 驗證
      # top_up: 儲值
      # bonus: 系統贈送
      t.string :action_type, null: false

      # Token 使用詳情 (JSONB)
      # { input_tokens: 123, output_tokens: 456, total_tokens: 579 }
      t.jsonb :token_usage, default: {}

      # 其他元數據
      # { query: "...", model: "gemini-2.0-flash", ... }
      t.jsonb :metadata, default: {}

      t.datetime :created_at, null: false
    end

    add_index :ai_credit_transactions, :action_type
    add_index :ai_credit_transactions, :created_at
  end
end
