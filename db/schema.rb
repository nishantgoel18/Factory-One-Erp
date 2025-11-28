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

ActiveRecord::Schema[8.1].define(version: 2025_11_28_224246) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "account_type"
    t.string "code"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.boolean "is_active", default: false
    t.boolean "is_cash_flow_account", default: false
    t.string "name"
    t.string "sub_type"
    t.datetime "updated_at", null: false
  end

  create_table "bill_of_materials", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.integer "created_by"
    t.boolean "deleted", default: false
    t.date "effective_from"
    t.date "effective_to"
    t.boolean "is_default", default: false
    t.string "name"
    t.text "notes"
    t.bigint "product_id"
    t.string "revision"
    t.string "status", default: "DRAFT"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_bill_of_materials_on_code", unique: true
    t.index ["product_id"], name: "index_bill_of_materials_on_product_id"
  end

  create_table "bom_items", force: :cascade do |t|
    t.bigint "bill_of_material_id"
    t.bigint "component_id"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.text "line_note"
    t.decimal "quantity", precision: 14, scale: 4, default: "0.0"
    t.decimal "scrap_percent", precision: 5, scale: 2, default: "0.0"
    t.bigint "uom_id"
    t.datetime "updated_at", null: false
    t.index ["bill_of_material_id"], name: "index_bom_items_on_bill_of_material_id"
    t.index ["component_id"], name: "index_bom_items_on_component_id"
    t.index ["uom_id"], name: "index_bom_items_on_uom_id"
  end

  create_table "customers", force: :cascade do |t|
    t.boolean "allow_backorders", default: true
    t.text "billing_address"
    t.string "billing_city"
    t.string "billing_country", default: "US"
    t.string "billing_postal_code"
    t.string "billing_state"
    t.string "billing_street"
    t.string "business_number"
    t.string "code", limit: 20
    t.datetime "created_at", null: false
    t.integer "created_by_id"
    t.decimal "credit_limit", precision: 15, scale: 2, default: "0.0"
    t.decimal "current_balance", precision: 15, scale: 2, default: "0.0"
    t.string "customer_tax_region"
    t.string "customer_type", limit: 20
    t.string "dba_name"
    t.integer "default_ar_account_id"
    t.string "default_currency", limit: 3, default: "USD"
    t.integer "default_price_list_id"
    t.integer "default_sales_rep_id"
    t.integer "default_tax_code_id"
    t.integer "default_warehouse_id"
    t.boolean "deleted", default: false
    t.text "delivery_instructions"
    t.string "ein_number"
    t.string "email"
    t.string "fax", limit: 20
    t.string "freight_terms", limit: 20
    t.string "full_name", limit: 255
    t.text "internal_notes"
    t.boolean "is_active", default: false
    t.string "legal_name"
    t.string "mobile", limit: 20
    t.string "payment_terms", limit: 20
    t.string "phone_number"
    t.string "primary_contact_email"
    t.string "primary_contact_name"
    t.string "primary_contact_phone", limit: 20
    t.string "secondary_contact_email"
    t.string "secondary_contact_name"
    t.string "secondary_contact_phone", limit: 20
    t.text "shipping_address"
    t.string "shipping_city"
    t.string "shipping_country", default: "US"
    t.string "shipping_method"
    t.string "shipping_postal_code"
    t.string "shipping_state"
    t.string "shipping_street"
    t.boolean "tax_exempt", default: false
    t.string "tax_exempt_number"
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["created_by_id"], name: "index_customers_on_created_by_id"
    t.index ["default_ar_account_id"], name: "index_customers_on_default_ar_account_id"
    t.index ["default_tax_code_id"], name: "index_customers_on_default_tax_code_id"
  end

  create_table "journal_entries", force: :cascade do |t|
    t.string "accounting_period"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.text "description"
    t.date "entry_date"
    t.string "entry_number"
    t.boolean "is_reversal", default: false
    t.datetime "posted_at"
    t.integer "posted_by"
    t.string "reference_id"
    t.string "reference_type"
    t.integer "reversal_entry_id"
    t.boolean "reversed", default: false
    t.datetime "reversed_at"
    t.decimal "total_credit"
    t.decimal "total_debit"
    t.datetime "updated_at", null: false
    t.index ["posted_by"], name: "index_journal_entries_on_posted_by"
  end

  create_table "journal_lines", force: :cascade do |t|
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.decimal "credit", default: "0.0"
    t.decimal "debit", default: "0.0"
    t.boolean "deleted", default: false
    t.text "description"
    t.integer "journal_entry_id"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_journal_lines_on_account_id"
    t.index ["journal_entry_id"], name: "index_journal_lines_on_journal_entry_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.boolean "is_pickable"
    t.boolean "is_receivable"
    t.string "name"
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id", null: false
    t.index ["warehouse_id"], name: "index_locations_on_warehouse_id"
  end

  create_table "product_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.string "name"
    t.integer "parent_id"
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_product_categories_on_parent_id"
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.boolean "is_active"
    t.boolean "is_batch_tracked"
    t.boolean "is_serial_tracked"
    t.boolean "is_stocked"
    t.string "name"
    t.integer "product_category_id"
    t.string "product_type"
    t.decimal "reorder_point"
    t.string "sku"
    t.decimal "standard_cost"
    t.integer "unit_of_measure_id"
    t.datetime "updated_at", null: false
    t.index ["product_category_id"], name: "index_products_on_product_category_id"
    t.index ["unit_of_measure_id"], name: "index_products_on_unit_of_measure_id"
  end

  create_table "stock_batches", force: :cascade do |t|
    t.string "batch_number"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.boolean "deleted", default: false
    t.date "expiry_date"
    t.boolean "is_active", default: true
    t.date "manufacture_date"
    t.text "note"
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_stock_batches_on_created_by_id"
    t.index ["product_id"], name: "index_stock_batches_on_product_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.text "billing_address"
    t.string "code"
    t.datetime "created_at", null: false
    t.integer "created_by"
    t.boolean "deleted"
    t.string "email"
    t.boolean "is_active"
    t.integer "lead_time_days"
    t.string "name"
    t.decimal "on_time_delivery_rate", precision: 5, scale: 2, default: "100.0"
    t.string "phone"
    t.text "shipping_address"
    t.datetime "updated_at", null: false
  end

  create_table "tax_codes", force: :cascade do |t|
    t.string "city"
    t.string "code", limit: 20
    t.string "compounds_on"
    t.string "country", default: "US"
    t.string "county"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.date "effective_from"
    t.date "effective_to"
    t.string "filing_frequency", default: "MONTHLY"
    t.boolean "is_active", default: true
    t.boolean "is_compound", default: false
    t.string "jurisdiction"
    t.string "name"
    t.decimal "rate", precision: 6, scale: 4, default: "0.0"
    t.string "state_province"
    t.string "tax_authority_id"
    t.string "tax_type"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_tax_codes_on_code", unique: true
  end

  create_table "unit_of_measures", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.boolean "is_decimal"
    t.string "name"
    t.string "symbol"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "full_name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "warehouses", force: :cascade do |t|
    t.text "address"
    t.string "code"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.boolean "is_active"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "bill_of_materials", "products"
  add_foreign_key "bom_items", "bill_of_materials"
  add_foreign_key "bom_items", "products", column: "component_id"
  add_foreign_key "bom_items", "unit_of_measures", column: "uom_id"
  add_foreign_key "locations", "warehouses"
  add_foreign_key "stock_batches", "products"
  add_foreign_key "stock_batches", "users", column: "created_by_id"
end
