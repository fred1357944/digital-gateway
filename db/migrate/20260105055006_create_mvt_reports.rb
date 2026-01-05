class CreateMvtReports < ActiveRecord::Migration[8.1]
  def change
    create_table :mvt_reports do |t|
      t.references :product, null: false, foreign_key: true
      t.decimal :score
      t.integer :status
      t.jsonb :details

      t.timestamps
    end
  end
end
