# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_05_11_170211) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "author_calendar_items", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "user_id"
    t.date "start_date", null: false
    t.string "what", null: false
    t.string "where"
    t.string "event_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bookshelf_friends", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "purchaser_email"
    t.boolean "purchaser_accepts_terms"
    t.datetime "purchaser_terms_date"
    t.string "reader_name"
    t.string "reader_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fotb_coupons", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "bookshelf_friends_id", null: false
    t.string "coupon_name"
    t.date "expires"
    t.string "sendowl_coupon_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bookshelf_friends_id"], name: "index_fotb_coupons_on_bookshelf_friends_id"
  end

  create_table "fotb_payments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "bookshelf_friends_id", null: false
    t.decimal "amount", precision: 10
    t.boolean "successful"
    t.json "stripe_charge"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bookshelf_friends_id"], name: "index_fotb_payments_on_bookshelf_friends_id"
  end

  create_table "images", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "file_name"
    t.string "product_code"
    t.string "product_code_and_variant"
    t.string "bucket"
    t.string "path_in_bucket"
    t.string "url"
    t.integer "width"
    t.integer "height"
    t.bigint "images_id"
    t.integer "update_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.string "content_type"
    t.index ["images_id"], name: "index_images_on_images_id"
    t.index ["product_code_and_variant"], name: "index_images_on_product_code_and_variant"
  end

  create_table "oauth_access_grants", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.string "scopes"
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "oauth_openid_requests", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "access_grant_id", null: false
    t.string "nonce", null: false
    t.index ["access_grant_id"], name: "index_oauth_openid_requests_on_access_grant_id"
  end

  create_table "royalty_raw_lp_data", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "upload_id", null: false
    t.bigint "sku_id"
    t.string "isbn", null: false
    t.string "e_isbn"
    t.string "title", null: false
    t.string "publisher", null: false
    t.string "author", null: false
    t.string "channel", null: false
    t.decimal "sales", precision: 10, scale: 2, null: false
    t.decimal "commission_rate", precision: 5, scale: 2, null: false
    t.decimal "commission_earned", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["isbn"], name: "index_royalty_raw_lp_data_on_isbn"
    t.index ["sku_id"], name: "index_royalty_raw_lp_data_on_sku_id"
    t.index ["upload_id"], name: "index_royalty_raw_lp_data_on_upload_id"
  end

  create_table "sessions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "uploads", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "upload_channel", null: false
    t.string "status", null: false
    t.datetime "uploaded_at", null: false
    t.datetime "date_on_report"
    t.string "report_period"
    t.decimal "statement_total", precision: 10, scale: 2, default: "0.0"
    t.string "filename"
    t.integer "filesize"
    t.datetime "imported_at"
    t.text "error_msg"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date_on_report"], name: "index_uploads_on_date_on_report", unique: true
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.boolean "verified", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "woo_line_items", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "woo_order_id"
    t.integer "woo_li_or_ri_id"
    t.datetime "woo_modified_dtm"
    t.boolean "is_ri"
    t.string "sku", limit: 30
    t.integer "qty"
    t.decimal "amount", precision: 10, scale: 2
    t.integer "import_to_royalties_batch_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["woo_li_or_ri_id"], name: "index_woo_line_items_on_woo_li_or_ri_id", unique: true
    t.index ["woo_modified_dtm"], name: "index_woo_line_items_on_woo_modified_dtm"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "fotb_coupons", "bookshelf_friends", column: "bookshelf_friends_id"
  add_foreign_key "fotb_payments", "bookshelf_friends", column: "bookshelf_friends_id"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_openid_requests", "oauth_access_grants", column: "access_grant_id", on_delete: :cascade
  add_foreign_key "royalty_raw_lp_data", "uploads"
end
