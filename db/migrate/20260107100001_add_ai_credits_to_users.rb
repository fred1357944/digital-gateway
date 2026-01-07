# frozen_string_literal: true

class AddAiCreditsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :ai_credits, :integer, default: 100, null: false
    add_index :users, :ai_credits
  end
end
