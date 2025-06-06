class CreateUploadWrappers < ActiveRecord::Migration[8.0]
  def change
    create_table :upload_wrappers do |t|
      t.datetime :uploaded_at
      t.integer :size
      t.string :filename
      t.string :mime_type
      t.string :status
      t.text :status_message

      t.integer :id_of_created_object, null: true

      t.timestamps
    end
  end
end
