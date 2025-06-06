class CreateIpsRevenueLine < ActiveRecord::Migration[8.0]
  def change
    create_table :ips_revenue_lines do |t|
      t.references :ips_statement_details, null: true,  foreign_key: true
      t.references :upload_wrapper,        null: false, foreign_key: true
      t.integer    :sku_id            # cross db fk

      t.string  :ean
      t.string  :title
      t.string  :format
      t.decimal :list_amount, precision: 8, scale: 2
      t.string  :pub_alpha
      t.string  :brand_category
      t.string  :imprint
      t.string  :date
      t.string  :customer_po_or_claim_no
      t.string  :invoice_or_credit_memo_no
      t.decimal :customer_discount, precision: 6, scale: 5
      t.string  :type
      t.integer :qty
      t.decimal :value, precision: 8, scale: 2
      t.string  :hq_account_no
      t.string  :headquarter
      t.string  :shipping_location
      t.string  :sl_city
      t.string  :sl_state

      t.timestamps
    end
  end
end
