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

ActiveRecord::Schema[8.1].define(version: 2025_12_02_090552) do
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

  create_table "cycle_count_lines", force: :cascade do |t|
    t.bigint "batch_id"
    t.decimal "counted_qty", precision: 14, scale: 4
    t.datetime "created_at", null: false
    t.bigint "cycle_count_id", null: false
    t.boolean "deleted", default: false, null: false
    t.text "line_note"
    t.string "line_status", limit: 20, default: "PENDING"
    t.bigint "location_id", null: false
    t.bigint "product_id", null: false
    t.decimal "system_qty", precision: 14, scale: 4, default: "0.0"
    t.bigint "uom_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "variance", precision: 14, scale: 4
    t.index ["batch_id"], name: "index_cycle_count_lines_on_batch_id"
    t.index ["cycle_count_id", "product_id"], name: "index_cycle_count_lines_on_cycle_count_id_and_product_id"
    t.index ["cycle_count_id"], name: "index_cycle_count_lines_on_cycle_count_id"
    t.index ["line_status"], name: "index_cycle_count_lines_on_line_status"
    t.index ["location_id"], name: "index_cycle_count_lines_on_location_id"
    t.index ["product_id"], name: "index_cycle_count_lines_on_product_id"
    t.index ["uom_id"], name: "index_cycle_count_lines_on_uom_id"
  end

  create_table "cycle_counts", force: :cascade do |t|
    t.datetime "count_completed_at"
    t.datetime "count_started_at"
    t.string "count_type", limit: 30
    t.bigint "counted_by_id"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.integer "lines_with_variance_count", default: 0
    t.text "notes"
    t.datetime "posted_at"
    t.integer "posted_by"
    t.bigint "posted_by_id"
    t.string "reference_no", limit: 50, null: false
    t.datetime "scheduled_at", null: false
    t.bigint "scheduled_by_id"
    t.string "status", limit: 20, default: "SCHEDULED", null: false
    t.integer "total_lines_count", default: 0
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id", null: false
    t.index ["counted_by_id"], name: "index_cycle_counts_on_counted_by_id"
    t.index ["posted_by"], name: "index_cycle_counts_on_posted_by"
    t.index ["posted_by_id"], name: "index_cycle_counts_on_posted_by_id"
    t.index ["reference_no"], name: "index_cycle_counts_on_reference_no", unique: true
    t.index ["scheduled_at"], name: "index_cycle_counts_on_scheduled_at"
    t.index ["scheduled_by_id"], name: "index_cycle_counts_on_scheduled_by_id"
    t.index ["status"], name: "index_cycle_counts_on_status"
    t.index ["warehouse_id", "status"], name: "index_cycle_counts_on_warehouse_id_and_status"
    t.index ["warehouse_id"], name: "index_cycle_counts_on_warehouse_id"
  end

  create_table "goods_receipt_lines", force: :cascade do |t|
    t.bigint "batch_id"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.bigint "goods_receipt_id", null: false
    t.text "line_note"
    t.bigint "location_id", null: false
    t.bigint "product_id", null: false
    t.decimal "qty", precision: 14, scale: 4, default: "0.0", null: false
    t.decimal "unit_cost", precision: 15, scale: 4
    t.bigint "uom_id", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_goods_receipt_lines_on_batch_id"
    t.index ["goods_receipt_id", "product_id"], name: "index_goods_receipt_lines_on_goods_receipt_id_and_product_id"
    t.index ["goods_receipt_id"], name: "index_goods_receipt_lines_on_goods_receipt_id"
    t.index ["location_id"], name: "index_goods_receipt_lines_on_location_id"
    t.index ["product_id"], name: "index_goods_receipt_lines_on_product_id"
    t.index ["uom_id"], name: "index_goods_receipt_lines_on_uom_id"
  end

  create_table "goods_receipts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.boolean "deleted", default: false, null: false
    t.text "notes"
    t.datetime "posted_at"
    t.bigint "posted_by_id"
    t.bigint "purchase_order_id"
    t.date "receipt_date", default: -> { "CURRENT_DATE" }, null: false
    t.string "reference_no", limit: 50, null: false
    t.string "status", limit: 20, default: "DRAFT", null: false
    t.bigint "supplier_id"
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id", null: false
    t.index ["created_by_id"], name: "index_goods_receipts_on_created_by_id"
    t.index ["posted_by_id"], name: "index_goods_receipts_on_posted_by_id"
    t.index ["purchase_order_id"], name: "index_goods_receipts_on_purchase_order_id"
    t.index ["reference_no"], name: "index_goods_receipts_on_reference_no", unique: true
    t.index ["status"], name: "index_goods_receipts_on_status"
    t.index ["supplier_id"], name: "index_goods_receipts_on_supplier_id"
    t.index ["warehouse_id", "status"], name: "index_goods_receipts_on_warehouse_id_and_status"
    t.index ["warehouse_id"], name: "index_goods_receipts_on_warehouse_id"
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

  create_table "purchase_order_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.date "expected_delivery_date"
    t.text "line_note"
    t.string "line_status", limit: 30, default: "OPEN"
    t.decimal "line_total", precision: 15, scale: 2, default: "0.0"
    t.decimal "ordered_qty", precision: 14, scale: 4, default: "0.0", null: false
    t.bigint "product_id", null: false
    t.bigint "purchase_order_id", null: false
    t.decimal "received_qty", precision: 14, scale: 4, default: "0.0"
    t.decimal "tax_amount", precision: 15, scale: 2, default: "0.0"
    t.bigint "tax_code_id"
    t.decimal "tax_rate", precision: 6, scale: 4, default: "0.0"
    t.decimal "unit_price", precision: 15, scale: 4, default: "0.0", null: false
    t.bigint "uom_id", null: false
    t.datetime "updated_at", null: false
    t.index ["line_status"], name: "index_purchase_order_lines_on_line_status"
    t.index ["product_id"], name: "index_purchase_order_lines_on_product_id"
    t.index ["purchase_order_id"], name: "index_purchase_order_lines_on_purchase_order_id"
    t.index ["tax_code_id"], name: "index_purchase_order_lines_on_tax_code_id"
    t.index ["uom_id"], name: "index_purchase_order_lines_on_uom_id"
  end

  create_table "purchase_orders", force: :cascade do |t|
    t.date "closed_at"
    t.bigint "closed_by_id"
    t.date "confirmed_at"
    t.bigint "confirmed_by_id"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "currency", limit: 3, default: "USD", null: false
    t.boolean "deleted", default: false, null: false
    t.date "expected_date"
    t.text "internal_notes"
    t.text "notes"
    t.date "order_date", default: -> { "CURRENT_DATE" }, null: false
    t.string "payment_terms", limit: 50
    t.string "po_number", limit: 50, null: false
    t.text "shipping_address"
    t.decimal "shipping_cost", precision: 15, scale: 2, default: "0.0"
    t.string "shipping_method", limit: 100
    t.string "status", limit: 30, default: "DRAFT", null: false
    t.decimal "subtotal", precision: 15, scale: 2, default: "0.0"
    t.bigint "supplier_id", null: false
    t.decimal "tax_amount", precision: 15, scale: 2, default: "0.0"
    t.decimal "total_amount", precision: 15, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id"
    t.index ["closed_by_id"], name: "index_purchase_orders_on_closed_by_id"
    t.index ["confirmed_by_id"], name: "index_purchase_orders_on_confirmed_by_id"
    t.index ["created_by_id"], name: "index_purchase_orders_on_created_by_id"
    t.index ["expected_date"], name: "index_purchase_orders_on_expected_date"
    t.index ["order_date"], name: "index_purchase_orders_on_order_date"
    t.index ["po_number"], name: "index_purchase_orders_on_po_number", unique: true
    t.index ["status"], name: "index_purchase_orders_on_status"
    t.index ["supplier_id", "status"], name: "index_purchase_orders_on_supplier_id_and_status"
    t.index ["supplier_id"], name: "index_purchase_orders_on_supplier_id"
    t.index ["warehouse_id"], name: "index_purchase_orders_on_warehouse_id"
  end

  create_table "stock_adjustment_lines", force: :cascade do |t|
    t.bigint "batch_id"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.text "line_note"
    t.text "line_reason"
    t.bigint "location_id", null: false
    t.bigint "product_id", null: false
    t.decimal "qty_delta", precision: 14, scale: 4, default: "0.0", null: false
    t.bigint "stock_adjustment_id", null: false
    t.decimal "system_qty_at_adjustment", precision: 14, scale: 4
    t.bigint "uom_id", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_stock_adjustment_lines_on_batch_id"
    t.index ["location_id"], name: "index_stock_adjustment_lines_on_location_id"
    t.index ["product_id"], name: "index_stock_adjustment_lines_on_product_id"
    t.index ["stock_adjustment_id", "product_id"], name: "idx_on_stock_adjustment_id_product_id_b56b61a95f"
    t.index ["stock_adjustment_id"], name: "index_stock_adjustment_lines_on_stock_adjustment_id"
    t.index ["uom_id"], name: "index_stock_adjustment_lines_on_uom_id"
  end

  create_table "stock_adjustments", force: :cascade do |t|
    t.date "adjustment_date", default: -> { "CURRENT_DATE" }, null: false
    t.bigint "approved_by_id"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.boolean "deleted", default: false, null: false
    t.text "notes"
    t.datetime "posted_at"
    t.integer "posted_by"
    t.bigint "posted_by_id"
    t.text "reason", null: false
    t.string "reference_no", limit: 50, null: false
    t.string "status", limit: 20, default: "DRAFT", null: false
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id", null: false
    t.index ["adjustment_date"], name: "index_stock_adjustments_on_adjustment_date"
    t.index ["approved_by_id"], name: "index_stock_adjustments_on_approved_by_id"
    t.index ["created_by_id"], name: "index_stock_adjustments_on_created_by_id"
    t.index ["posted_by"], name: "index_stock_adjustments_on_posted_by"
    t.index ["posted_by_id"], name: "index_stock_adjustments_on_posted_by_id"
    t.index ["reference_no"], name: "index_stock_adjustments_on_reference_no", unique: true
    t.index ["status"], name: "index_stock_adjustments_on_status"
    t.index ["warehouse_id", "status"], name: "index_stock_adjustments_on_warehouse_id_and_status"
    t.index ["warehouse_id"], name: "index_stock_adjustments_on_warehouse_id"
  end

  create_table "stock_batches", force: :cascade do |t|
    t.string "batch_number"
    t.string "certificate_number"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.boolean "deleted", default: false
    t.date "expiry_date"
    t.boolean "is_active", default: true
    t.date "manufacture_date"
    t.text "note"
    t.text "notes"
    t.bigint "product_id", null: false
    t.string "quality_status"
    t.string "supplier_batch_ref"
    t.string "supplier_lot_number"
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_stock_batches_on_created_by_id"
    t.index ["product_id"], name: "index_stock_batches_on_product_id"
  end

  create_table "stock_issue_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.integer "from_location_id", null: false
    t.bigint "product_id", null: false
    t.decimal "quantity"
    t.bigint "stock_batch_id"
    t.bigint "stock_issue_id", null: false
    t.datetime "updated_at", null: false
    t.index ["from_location_id"], name: "index_stock_issue_lines_on_from_location_id"
    t.index ["product_id"], name: "index_stock_issue_lines_on_product_id"
    t.index ["stock_batch_id"], name: "index_stock_issue_lines_on_stock_batch_id"
    t.index ["stock_issue_id"], name: "index_stock_issue_lines_on_stock_issue_id"
  end

  create_table "stock_issues", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "created_by"
    t.integer "created_by_id"
    t.boolean "deleted"
    t.datetime "posted_at"
    t.integer "posted_by"
    t.string "reference_no"
    t.string "status"
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id", null: false
    t.index ["created_by_id"], name: "index_stock_issues_on_created_by_id"
    t.index ["posted_by"], name: "index_stock_issues_on_posted_by"
    t.index ["warehouse_id"], name: "index_stock_issues_on_warehouse_id"
  end

  create_table "stock_levels", force: :cascade do |t|
    t.bigint "batch_id"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.bigint "location_id", null: false
    t.decimal "on_hand_qty", precision: 20, scale: 6, default: "0.0", null: false
    t.bigint "product_id", null: false
    t.decimal "reserved_qty", precision: 20, scale: 6, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_stock_levels_on_batch_id"
    t.index ["location_id"], name: "index_stock_levels_on_location_id"
    t.index ["product_id", "location_id", "batch_id"], name: "index_stock_levels_on_product_location_batch", unique: true
    t.index ["product_id"], name: "index_stock_levels_on_product_id"
  end

  create_table "stock_transactions", force: :cascade do |t|
    t.bigint "batch_id"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.boolean "deleted", default: false, null: false
    t.bigint "from_location_id"
    t.text "note"
    t.bigint "product_id", null: false
    t.decimal "quantity", precision: 14, scale: 4, null: false
    t.string "reference_id", limit: 50
    t.string "reference_type", limit: 50
    t.bigint "to_location_id"
    t.string "txn_type", limit: 30, null: false
    t.bigint "uom_id", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_stock_transactions_on_batch_id"
    t.index ["created_by_id"], name: "index_stock_transactions_on_created_by_id"
    t.index ["from_location_id"], name: "index_stock_transactions_on_from_location_id"
    t.index ["product_id", "txn_type"], name: "index_stock_transactions_on_product_id_and_txn_type"
    t.index ["product_id"], name: "index_stock_transactions_on_product_id"
    t.index ["to_location_id"], name: "index_stock_transactions_on_to_location_id"
    t.index ["uom_id"], name: "index_stock_transactions_on_uom_id"
  end

  create_table "stock_transfer_lines", force: :cascade do |t|
    t.bigint "batch_id"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.bigint "from_location_id", null: false
    t.text "line_note"
    t.bigint "product_id", null: false
    t.decimal "qty", precision: 14, scale: 4, default: "0.0", null: false
    t.bigint "stock_transfer_id", null: false
    t.bigint "to_location_id", null: false
    t.bigint "uom_id", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_stock_transfer_lines_on_batch_id"
    t.index ["from_location_id"], name: "index_stock_transfer_lines_on_from_location_id"
    t.index ["product_id"], name: "index_stock_transfer_lines_on_product_id"
    t.index ["stock_transfer_id"], name: "index_stock_transfer_lines_on_stock_transfer_id"
    t.index ["to_location_id"], name: "index_stock_transfer_lines_on_to_location_id"
    t.index ["uom_id"], name: "index_stock_transfer_lines_on_uom_id"
  end

  create_table "stock_transfers", force: :cascade do |t|
    t.bigint "approved_by_id"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.boolean "deleted", default: false, null: false
    t.bigint "from_warehouse_id", null: false
    t.text "note"
    t.datetime "posted_at"
    t.integer "posted_by"
    t.bigint "requested_by_id"
    t.string "status", limit: 20, default: "DRAFT", null: false
    t.bigint "to_warehouse_id", null: false
    t.string "transfer_number", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_stock_transfers_on_approved_by_id"
    t.index ["created_by_id"], name: "index_stock_transfers_on_created_by_id"
    t.index ["from_warehouse_id"], name: "index_stock_transfers_on_from_warehouse_id"
    t.index ["posted_by"], name: "index_stock_transfers_on_posted_by"
    t.index ["requested_by_id"], name: "index_stock_transfers_on_requested_by_id"
    t.index ["to_warehouse_id"], name: "index_stock_transfers_on_to_warehouse_id"
    t.index ["transfer_number"], name: "index_stock_transfers_on_transfer_number", unique: true
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
  add_foreign_key "cycle_count_lines", "cycle_counts"
  add_foreign_key "cycle_count_lines", "locations"
  add_foreign_key "cycle_count_lines", "products"
  add_foreign_key "cycle_count_lines", "stock_batches", column: "batch_id"
  add_foreign_key "cycle_count_lines", "unit_of_measures", column: "uom_id"
  add_foreign_key "cycle_counts", "users", column: "counted_by_id"
  add_foreign_key "cycle_counts", "users", column: "posted_by_id"
  add_foreign_key "cycle_counts", "users", column: "scheduled_by_id"
  add_foreign_key "cycle_counts", "warehouses"
  add_foreign_key "goods_receipt_lines", "goods_receipts"
  add_foreign_key "goods_receipt_lines", "locations"
  add_foreign_key "goods_receipt_lines", "products"
  add_foreign_key "goods_receipt_lines", "stock_batches", column: "batch_id"
  add_foreign_key "goods_receipt_lines", "unit_of_measures", column: "uom_id"
  add_foreign_key "goods_receipts", "purchase_orders"
  add_foreign_key "goods_receipts", "suppliers"
  add_foreign_key "goods_receipts", "users", column: "created_by_id"
  add_foreign_key "goods_receipts", "users", column: "posted_by_id"
  add_foreign_key "goods_receipts", "warehouses"
  add_foreign_key "locations", "warehouses"
  add_foreign_key "purchase_order_lines", "products"
  add_foreign_key "purchase_order_lines", "purchase_orders"
  add_foreign_key "purchase_order_lines", "tax_codes"
  add_foreign_key "purchase_order_lines", "unit_of_measures", column: "uom_id"
  add_foreign_key "purchase_orders", "suppliers"
  add_foreign_key "purchase_orders", "users", column: "closed_by_id"
  add_foreign_key "purchase_orders", "users", column: "confirmed_by_id"
  add_foreign_key "purchase_orders", "users", column: "created_by_id"
  add_foreign_key "purchase_orders", "warehouses"
  add_foreign_key "stock_adjustment_lines", "locations"
  add_foreign_key "stock_adjustment_lines", "products"
  add_foreign_key "stock_adjustment_lines", "stock_adjustments"
  add_foreign_key "stock_adjustment_lines", "stock_batches", column: "batch_id"
  add_foreign_key "stock_adjustment_lines", "unit_of_measures", column: "uom_id"
  add_foreign_key "stock_adjustments", "users", column: "approved_by_id"
  add_foreign_key "stock_adjustments", "users", column: "created_by_id"
  add_foreign_key "stock_adjustments", "users", column: "posted_by_id"
  add_foreign_key "stock_adjustments", "warehouses"
  add_foreign_key "stock_batches", "products"
  add_foreign_key "stock_batches", "users", column: "created_by_id"
  add_foreign_key "stock_issue_lines", "products"
  add_foreign_key "stock_issue_lines", "stock_batches"
  add_foreign_key "stock_issue_lines", "stock_issues"
  add_foreign_key "stock_issues", "warehouses"
  add_foreign_key "stock_levels", "locations"
  add_foreign_key "stock_levels", "products"
  add_foreign_key "stock_levels", "stock_batches", column: "batch_id"
  add_foreign_key "stock_transactions", "locations", column: "from_location_id"
  add_foreign_key "stock_transactions", "locations", column: "to_location_id"
  add_foreign_key "stock_transactions", "products"
  add_foreign_key "stock_transactions", "stock_batches", column: "batch_id"
  add_foreign_key "stock_transactions", "unit_of_measures", column: "uom_id"
  add_foreign_key "stock_transactions", "users", column: "created_by_id"
  add_foreign_key "stock_transfer_lines", "locations", column: "from_location_id"
  add_foreign_key "stock_transfer_lines", "locations", column: "to_location_id"
  add_foreign_key "stock_transfer_lines", "products"
  add_foreign_key "stock_transfer_lines", "stock_batches", column: "batch_id"
  add_foreign_key "stock_transfer_lines", "stock_transfers"
  add_foreign_key "stock_transfer_lines", "unit_of_measures", column: "uom_id"
  add_foreign_key "stock_transfers", "users", column: "approved_by_id"
  add_foreign_key "stock_transfers", "users", column: "created_by_id"
  add_foreign_key "stock_transfers", "users", column: "requested_by_id"
  add_foreign_key "stock_transfers", "warehouses", column: "from_warehouse_id"
  add_foreign_key "stock_transfers", "warehouses", column: "to_warehouse_id"
end
