# frozen_string_literal: true

class CreateProductScores < ActiveRecord::Migration[8.1]
  def change
    create_table :product_scores do |t|
      t.references :product, null: false, foreign_key: true, index: { unique: true }

      # Multi-objective scores (0-100)
      t.integer :price_score, default: 50, null: false
      t.integer :quality_score, default: 50, null: false
      t.integer :speed_score, default: 50, null: false
      t.integer :reputation_score, default: 50, null: false
      t.integer :relevance_score, default: 50, null: false

      # Metadata
      t.datetime :calculated_at
      t.string :calculation_version, default: "1.0"

      t.timestamps
    end

    # Index for finding products with high scores in specific dimensions
    add_index :product_scores, :price_score
    add_index :product_scores, :quality_score
  end
end
