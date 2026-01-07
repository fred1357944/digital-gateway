# frozen_string_literal: true

class AddAiMetadataToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :ai_metadata, :jsonb, default: {}, null: false
    add_index :products, :ai_metadata, using: :gin
  end
end
