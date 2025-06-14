class CreateOhoErrors < ActiveRecord::Migration[8.0]
  def change
    create_table :oho_errors do |t|
      t.string  :owner_dom_id, null: false
      t.string  :display_tag,  null: true
      t.integer :level,        null: false, default: 0
      t.string  :label,        null: false
      t.string  :message,      limit: 2048

      t.timestamps
    end

    add_index :oho_errors, :owner_dom_id, name: 'index_oho_errors_on_owner_dom_id'
  end
end
