class CreateLpStatements < ActiveRecord::Migration[8.0]
  def change
    create_table :lp_statements do |t|
      t.references :upload_wrapper, null: false, foreign_key: true
      t.string :status
      t.date :date_on_report
      t.string :report_period
      t.decimal :statement_total, precision: 10, scale: 2, default: 0
      t.datetime :imported_at

      t.timestamps
    end
  end
end
