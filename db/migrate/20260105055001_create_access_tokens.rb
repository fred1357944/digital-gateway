class CreateAccessTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :access_tokens do |t|
      t.references :order, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :token
      t.datetime :expires_at
      t.integer :max_uses
      t.integer :use_count
      t.datetime :revoked_at

      t.timestamps
    end
    add_index :access_tokens, :token
  end
end
