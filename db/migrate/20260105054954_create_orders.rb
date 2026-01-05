class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :status
      t.decimal :total_amount
      t.string :merchant_trade_no
      t.string :ecpay_trade_no

      t.timestamps
    end
    add_index :orders, :merchant_trade_no
  end
end
