class CreateLpStatementLines < ActiveRecord::Migration[8.0]
  def change
    create_table :lp_statement_lines do |t|
      t.belongs_to :lp_statement, null: false, foreign_key: true

      t.references :sku
      t.string  :isbn,              null: false, index: true
      t.string  :e_isbn
      t.string  :title,             null: false
      t.string  :publisher,         null: false
      t.string  :author,            null: false
      t.string  :channel,           null: false
      t.decimal :sales,             null: false, precision: 10, scale: 2
      t.decimal :commission_rate,   null: false, precision: 5, scale: 2
      t.decimal :commission_earned, null: false, precision: 10, scale: 2

      t.timestamps
    end
  end
end
