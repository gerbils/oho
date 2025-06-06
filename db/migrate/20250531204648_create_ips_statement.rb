class CreateIpsStatement < ActiveRecord::Migration[8.0]
  def change
    create_table :ips_statements do |t|
      t.references :upload_wrapper,      null: false, foreign_key: true
      t.string     :status,              null: false
      t.date       :month_ending,        null: false
      t.decimal    :revenue,             default: 0,  precision: 10, scale: 2    # sales + returns
      t.decimal    :gross_sales_total,   default: 0,  precision: 10, scale: 2
      t.decimal    :gross_returns_total, default: 0,  precision: 10, scale: 2
      t.decimal    :net_sales,           default: 0,  precision: 10, scale: 2
      t.decimal    :expenses,            default: 0,  precision: 10, scale: 2
      t.decimal    :total_chargebacks,   default: 0,  precision: 10, scale: 2
      t.decimal    :total_expenses,      default: 0,  precision: 10, scale: 2
      t.decimal    :net_client_earnings, default: 0,  precision: 10, scale: 2
      t.datetime   :imported_at
      t.timestamps
    end
  end
end
