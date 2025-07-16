class CreateImportSummaries < ActiveRecord::Migration[8.0]
  def change
    create_table :import_summaries do |t|
      t.datetime :imported_at
      t.string   :import_class
      t.integer  :import_class_id
      t.decimal  :import_amount, precision: 10, scale: 2
      t.string   :notes

      t.timestamps
    end
  end
end
