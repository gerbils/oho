class CreateIpsPaymentAdvice < ActiveRecord::Migration[8.0]
  def change
    create_table :ips_payment_advices do |t|
      t.references :upload_wrapper, null: Rails.env.test?, foreign_key: true
      t.string :pay_cycle
      t.string :pay_cycle_seq_number
      t.string :payment_reference
      t.date    :payment_date
      t.decimal :total_amount, precision: 10, scale: 2

      t.string  :status, null: false, default: 'pending'
      t.string  :status_message
      t.timestamps
    end
  end
end
