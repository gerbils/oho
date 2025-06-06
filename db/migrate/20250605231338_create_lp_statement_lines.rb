class CreateLpStatementLines < ActiveRecord::Migration[8.0]
  def change
    create_table :lp_statement_lines do |t|
      t.references :lp_statement, null: false, foreign_key: true
      t.integer    :sku_id

      t.decimal :sales,             precision: 10, scale: 2, null: false, default: 0
      t.decimal :commission_earned, precision: 10, scale: 2, null: false, default: 0
      t.decimal :commission_rate,   precision: 5,  scale: 4, null: false, default: 0

      t.string :isbn
      t.string :e_isbn
      t.string :publisher
      t.string :title
      t.string :author

      t.timestamps
    end
  end
end
