class CreateTableTest < ActiveRecord::Migration[8.0]
  def change
    create_table :tests do |t|
      t.integer :count

      t.timestamps
    end
  end
end
