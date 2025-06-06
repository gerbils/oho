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

ActiveRecord::Schema[8.0].define(version: 2025_06_05_231338) do
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

  create_table "ips_revenue_lines", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "ips_statement_details_id"
    t.bigint "upload_wrapper_id", null: false
    t.integer "sku_id"
    t.string "ean"
    t.string "title"
    t.string "format"
    t.decimal "list_amount", precision: 8, scale: 2
    t.string "pub_alpha"
    t.string "brand_category"
    t.string "imprint"
    t.string "date"
    t.string "customer_po_or_claim_no"
    t.string "invoice_or_credit_memo_no"
    t.decimal "customer_discount", precision: 6, scale: 5
    t.string "type"
    t.integer "qty"
    t.decimal "value", precision: 8, scale: 2
    t.string "hq_account_no"
    t.string "headquarter"
    t.string "shipping_location"
    t.string "sl_city"
    t.string "sl_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ips_statement_details_id"], name: "index_ips_revenue_lines_on_ips_statement_details_id"
    t.index ["upload_wrapper_id"], name: "index_ips_revenue_lines_on_upload_wrapper_id"
  end

  create_table "ips_statement_details", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "ips_statement_id", null: false
    t.string "section", null: false
    t.string "subsection", null: false
    t.string "detail", null: false
    t.date "month_due"
    t.string "basis"
    t.decimal "basis_for_charge", precision: 10, scale: 2, null: false
    t.decimal "factor_or_rate", precision: 6, scale: 4, null: false
    t.decimal "due_this_month", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ips_statement_id"], name: "index_ips_statement_details_on_ips_statement_id"
  end

  create_table "ips_statements", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "upload_wrapper_id", null: false
    t.string "status", null: false
    t.date "month_ending", null: false
    t.decimal "revenue", precision: 10, scale: 2, default: "0.0"
    t.decimal "gross_sales_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "gross_returns_total", precision: 10, scale: 2, default: "0.0"
    t.decimal "net_sales", precision: 10, scale: 2, default: "0.0"
    t.decimal "expenses", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_chargebacks", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_expenses", precision: 10, scale: 2, default: "0.0"
    t.decimal "net_client_earnings", precision: 10, scale: 2, default: "0.0"
    t.datetime "imported_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["upload_wrapper_id"], name: "index_ips_statements_on_upload_wrapper_id"
  end

  create_table "lp_statement_lines", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "lp_statement_id", null: false
    t.integer "sku_id"
    t.decimal "sales", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "commission_earned", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "commission_rate", precision: 5, scale: 4, default: "0.0", null: false
    t.string "isbn"
    t.string "e_isbn"
    t.string "publisher"
    t.string "title"
    t.string "author"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lp_statement_id"], name: "index_lp_statement_lines_on_lp_statement_id"
  end

  create_table "lp_statements", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "upload_wrapper_id", null: false
    t.string "status"
    t.text "status_message"
    t.date "date_on_report"
    t.string "report_period"
    t.decimal "statement_total", precision: 10, scale: 2, default: "0.0"
    t.datetime "imported_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["upload_wrapper_id"], name: "index_lp_statements_on_upload_wrapper_id"
  end

  create_table "posts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "royalty_raw_lp_data", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "upload_wrapper_id", null: false
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
    t.index ["upload_wrapper_id"], name: "index_royalty_raw_lp_data_on_upload_wrapper_id"
  end

  create_table "sessions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "upload_wrappers", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "uploaded_at"
    t.integer "size"
    t.string "filename"
    t.string "mime_type"
    t.string "status"
    t.text "status_message"
    t.integer "id_of_created_object"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ips_revenue_lines", "ips_statement_details", column: "ips_statement_details_id"
  add_foreign_key "ips_revenue_lines", "upload_wrappers"
  add_foreign_key "ips_statement_details", "ips_statements"
  add_foreign_key "ips_statements", "upload_wrappers"
  add_foreign_key "lp_statement_lines", "lp_statements"
  add_foreign_key "lp_statements", "upload_wrappers"
  add_foreign_key "royalty_raw_lp_data", "upload_wrappers"
end
