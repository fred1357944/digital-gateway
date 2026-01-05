class CreateSellerProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :seller_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :status
      t.string :store_name
      t.text :description
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :seller_profiles, :discarded_at
  end
end
