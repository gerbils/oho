class CreateTableIpsReconciliations < ActiveRecord::Migration[8.0]
  def change
    create_table :ips_reconciliations do |t|
      t.references :ips_statement_detail, null: false, foreign_key: true
      t.references :ips_payment_advice_line, null: false, foreign_key: true

      t.timestamps
    end
  end
end
