class CreateIpsDetailLine < ActiveRecord::Migration[8.0]
  def change
    create_table :ips_detail_lines do |t|
      t.references :ips_statement_detail, null: true,  foreign_key: true
      t.integer    :sku_id, null: false            # cross db fk

      t.string  :content_type
      t.string  :description
      t.string  :title
      t.string  :ean
      t.integer :quantity
      t.decimal :amount, precision: 10, scale: 4
      t.json    :json

      t.timestamps
    end
  end
end

