class CreateIpsStatementDetail < ActiveRecord::Migration[8.0]
  def change
    create_table :ips_statement_details do |t|
      t.references :ips_statement,          null: false, foreign_key: true
      t.references :upload_wrapper,         null: true,  foreign_key: true
      t.integer    :ips_detail_lines_count, null: false, default: 0

      t.datetime   :uploaded_at,      null: true

      t.string     :section,          null: false      # REVENUE, EXPENSE
      t.string     :subsection,       null: false      # e.g. Gross Sales
      t.string     :detail,           null: false      # Ebook sales gross

      t.date       :month_due,        null: true

      t.string     :basis,            null: true

      t.decimal    :basis_for_charge, null: false, precision: 12, scale: 4
      t.decimal    :factor_or_rate,   null: false, precision: 6,  scale: 4
      t.decimal    :due_this_month,   null: false, precision: 12, scale: 4

      t.timestamps
    end
  end
end
