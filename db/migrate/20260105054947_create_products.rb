class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :seller_profile, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.decimal :price
      t.string :content_url
      t.string :preview_url
      t.integer :status
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :products, :discarded_at
  end
end
