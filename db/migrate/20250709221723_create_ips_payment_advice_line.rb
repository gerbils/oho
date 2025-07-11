class CreateIpsPaymentAdviceLine < ActiveRecord::Migration[8.0]
  def change
    create_table :ips_payment_advice_lines do |t|
      t.references :ips_payment_advice,   null: false, foreign_key: true
      t.references :ips_statement_detail, null: true,  foreign_key: true

      t.string  :invoice_number
      t.date    :invoice_date
      t.string  :voucher_id
      t.string  :status
      t.decimal :gross_amount, precision: 10, scale: 2
      t.decimal :discount_taken, precision: 10, scale: 2
      t.decimal :paid_amount, precision: 10, scale: 2

      t.timestamps
    end
  end
end
