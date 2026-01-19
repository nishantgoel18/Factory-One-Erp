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

ActiveRecord::Schema[8.1].define(version: 2026_01_11_204154) do
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
    t.bigint "organization_id"
    t.string "sub_type"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_accounts_on_organization_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
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
    t.bigint "organization_id"
    t.bigint "product_id"
    t.string "revision"
    t.string "status", default: "DRAFT"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_bill_of_materials_on_code", unique: true
    t.index ["organization_id"], name: "index_bill_of_materials_on_organization_id"
    t.index ["product_id"], name: "index_bill_of_materials_on_product_id"
  end

  create_table "bom_items", force: :cascade do |t|
    t.bigint "bill_of_material_id"
    t.bigint "component_id"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.text "line_note"
    t.bigint "organization_id"
    t.decimal "quantity", precision: 14, scale: 4, default: "0.0"
    t.decimal "scrap_percent", precision: 5, scale: 2, default: "0.0"
    t.bigint "uom_id"
    t.datetime "updated_at", null: false
    t.index ["bill_of_material_id"], name: "index_bom_items_on_bill_of_material_id"
    t.index ["component_id"], name: "index_bom_items_on_component_id"
    t.index ["organization_id"], name: "index_bom_items_on_organization_id"
    t.index ["uom_id"], name: "index_bom_items_on_uom_id"
  end

  create_table "customer_activities", force: :cascade do |t|
    t.datetime "activity_date", null: false
    t.string "activity_status", limit: 20, default: "COMPLETED"
    t.string "activity_type", limit: 30, null: false
    t.string "category", limit: 50
    t.string "communication_method", limit: 30
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.bigint "customer_contact_id"
    t.bigint "customer_id", null: false
    t.string "customer_sentiment", limit: 20
    t.boolean "deleted", default: false, null: false
    t.text "description"
    t.string "direction", limit: 10
    t.integer "duration_minutes"
    t.datetime "followup_date"
    t.boolean "followup_required", default: false
    t.string "next_action", limit: 255
    t.bigint "organization_id"
    t.string "outcome", limit: 50
    t.string "priority", limit: 20, default: "NORMAL"
    t.bigint "related_entity_id"
    t.string "related_entity_type"
    t.bigint "related_user_id"
    t.boolean "reminder_sent", default: false
    t.datetime "reminder_sent_at"
    t.string "subject", limit: 255, null: false
    t.string "tags", default: [], array: true
    t.datetime "updated_at", null: false
    t.index ["activity_status"], name: "index_customer_activities_on_activity_status"
    t.index ["created_by_id"], name: "index_customer_activities_on_created_by_id"
    t.index ["customer_contact_id"], name: "index_customer_activities_on_customer_contact_id"
    t.index ["customer_id", "activity_date"], name: "index_customer_activities_on_customer_id_and_activity_date", order: { activity_date: :desc }
    t.index ["customer_id", "activity_type"], name: "index_customer_activities_on_customer_id_and_activity_type"
    t.index ["customer_id", "deleted"], name: "index_customer_activities_on_customer_id_and_deleted"
    t.index ["customer_id"], name: "index_customer_activities_on_customer_id"
    t.index ["customer_sentiment"], name: "index_customer_activities_on_customer_sentiment"
    t.index ["followup_date", "followup_required"], name: "index_customer_activities_on_followup"
    t.index ["followup_date"], name: "index_customer_activities_on_followup_date"
    t.index ["organization_id"], name: "index_customer_activities_on_organization_id"
    t.index ["priority"], name: "index_customer_activities_on_priority"
    t.index ["related_entity_type", "related_entity_id"], name: "index_customer_activities_on_related_entity"
    t.index ["related_user_id"], name: "index_customer_activities_on_related_user_id"
    t.index ["tags"], name: "index_customer_activities_on_tags", using: :gin
  end

  create_table "customer_addresses", force: :cascade do |t|
    t.string "access_code", limit: 50
    t.string "address_label", limit: 100
    t.string "address_type", limit: 20, null: false
    t.string "attention_to", limit: 100
    t.string "city", limit: 100, null: false
    t.string "contact_email"
    t.string "contact_phone", limit: 20
    t.string "country", limit: 2, default: "US", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.bigint "customer_id", null: false
    t.boolean "deleted", default: false, null: false
    t.string "delivery_hours"
    t.text "delivery_instructions"
    t.string "dock_gate_info", limit: 100
    t.boolean "is_active", default: true
    t.boolean "is_default", default: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.bigint "organization_id"
    t.string "postal_code", limit: 20, null: false
    t.boolean "requires_appointment", default: false
    t.boolean "residential_address", default: false
    t.string "state_province", limit: 100
    t.string "street_address_1", limit: 255, null: false
    t.string "street_address_2", limit: 255
    t.datetime "updated_at", null: false
    t.index ["country"], name: "index_customer_addresses_on_country"
    t.index ["created_by_id"], name: "index_customer_addresses_on_created_by_id"
    t.index ["customer_id", "address_type"], name: "index_customer_addresses_on_customer_id_and_address_type"
    t.index ["customer_id", "deleted"], name: "index_customer_addresses_on_customer_id_and_deleted"
    t.index ["customer_id", "is_default"], name: "index_customer_addresses_on_customer_id_and_is_default"
    t.index ["customer_id"], name: "index_customer_addresses_on_customer_id"
    t.index ["is_active"], name: "index_customer_addresses_on_is_active"
    t.index ["organization_id"], name: "index_customer_addresses_on_organization_id"
    t.index ["postal_code"], name: "index_customer_addresses_on_postal_code"
  end

  create_table "customer_contacts", force: :cascade do |t|
    t.date "anniversary"
    t.date "birthday"
    t.text "contact_notes"
    t.string "contact_role", limit: 30, null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.bigint "customer_id", null: false
    t.boolean "deleted", default: false, null: false
    t.string "department", limit: 100
    t.string "email", limit: 255
    t.string "extension", limit: 10
    t.string "fax", limit: 20
    t.string "first_name", limit: 100, null: false
    t.boolean "is_active", default: true
    t.boolean "is_decision_maker", default: false
    t.boolean "is_primary_contact", default: false
    t.datetime "last_contacted_at"
    t.string "last_contacted_by", limit: 100
    t.text "last_interaction_notes"
    t.string "last_name", limit: 100, null: false
    t.string "linkedin_url"
    t.string "mobile", limit: 20
    t.bigint "organization_id"
    t.text "personal_notes"
    t.string "phone", limit: 20
    t.string "preferred_contact_method", limit: 20, default: "EMAIL"
    t.boolean "receive_invoice_copies", default: false
    t.boolean "receive_marketing_emails", default: false
    t.boolean "receive_order_confirmations", default: true
    t.boolean "receive_shipping_notifications", default: true
    t.string "skype_id", limit: 100
    t.string "title", limit: 100
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_customer_contacts_on_created_by_id"
    t.index ["customer_id", "contact_role"], name: "index_customer_contacts_on_customer_id_and_contact_role"
    t.index ["customer_id", "deleted"], name: "index_customer_contacts_on_customer_id_and_deleted"
    t.index ["customer_id", "is_primary_contact"], name: "index_customer_contacts_on_customer_id_and_is_primary_contact"
    t.index ["customer_id"], name: "index_customer_contacts_on_customer_id"
    t.index ["email"], name: "index_customer_contacts_on_email"
    t.index ["is_active"], name: "index_customer_contacts_on_is_active"
    t.index ["last_name", "first_name"], name: "index_customer_contacts_on_last_name_and_first_name"
    t.index ["organization_id"], name: "index_customer_contacts_on_organization_id"
  end

  create_table "customer_documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "customer_can_view", default: false
    t.bigint "customer_id", null: false
    t.boolean "deleted", default: false, null: false
    t.text "description"
    t.string "document_category", limit: 50
    t.string "document_title", limit: 255, null: false
    t.string "document_type", limit: 50, null: false
    t.date "effective_date"
    t.date "expiry_date"
    t.string "file_name", limit: 255
    t.integer "file_size"
    t.string "file_type", limit: 50
    t.string "file_url", limit: 500
    t.boolean "is_active", default: true
    t.boolean "is_confidential", default: false
    t.boolean "is_latest_version", default: true
    t.text "notes"
    t.bigint "organization_id"
    t.integer "renewal_reminder_days", default: 30
    t.boolean "requires_renewal", default: false
    t.bigint "superseded_by_id"
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_id"
    t.string "version", limit: 20, default: "1.0"
    t.index ["customer_id", "deleted"], name: "index_customer_documents_on_customer_id_and_deleted"
    t.index ["customer_id", "document_type"], name: "index_customer_documents_on_customer_id_and_document_type"
    t.index ["customer_id"], name: "index_customer_documents_on_customer_id"
    t.index ["expiry_date", "requires_renewal"], name: "index_customer_docs_on_expiry_and_renewal"
    t.index ["expiry_date"], name: "index_customer_documents_on_expiry_date"
    t.index ["is_active"], name: "index_customer_documents_on_is_active"
    t.index ["organization_id"], name: "index_customer_documents_on_organization_id"
    t.index ["superseded_by_id"], name: "index_customer_documents_on_superseded_by_id"
    t.index ["uploaded_by_id"], name: "index_customer_documents_on_uploaded_by_id"
  end

  create_table "customers", force: :cascade do |t|
    t.boolean "allow_backorders", default: true
    t.decimal "annual_revenue_potential", precision: 15, scale: 2
    t.datetime "approved_at"
    t.integer "approved_by_id"
    t.boolean "auto_invoice_email", default: true
    t.decimal "available_credit", precision: 15, scale: 2, default: "0.0"
    t.integer "average_days_to_pay", default: 0
    t.decimal "average_order_value", precision: 15, scale: 2, default: "0.0"
    t.string "bank_account_number"
    t.string "bank_name"
    t.string "bank_routing_number"
    t.text "billing_address"
    t.string "billing_city"
    t.string "billing_country", default: "US"
    t.string "billing_postal_code"
    t.string "billing_state"
    t.string "billing_street"
    t.string "business_number"
    t.string "code", limit: 20
    t.string "company_logo_url"
    t.datetime "created_at", null: false
    t.integer "created_by_id"
    t.boolean "credit_hold", default: false
    t.date "credit_hold_date"
    t.text "credit_hold_reason"
    t.decimal "credit_limit", precision: 15, scale: 2, default: "0.0"
    t.decimal "current_balance", precision: 15, scale: 2, default: "0.0"
    t.string "customer_acquisition_source", limit: 50
    t.string "customer_category", limit: 20
    t.decimal "customer_lifetime_value", precision: 15, scale: 2, default: "0.0"
    t.date "customer_since"
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
    t.decimal "discount_percentage", precision: 5, scale: 2, default: "0.0"
    t.decimal "early_payment_discount", precision: 5, scale: 2, default: "0.0"
    t.string "ein_number"
    t.string "email"
    t.string "expected_order_frequency", limit: 30
    t.string "facebook_url"
    t.string "fax", limit: 20
    t.string "freight_terms", limit: 20
    t.string "full_name", limit: 255
    t.string "industry_type", limit: 50
    t.text "internal_notes"
    t.boolean "is_active", default: false
    t.datetime "last_activity_date"
    t.integer "last_modified_by_id"
    t.decimal "last_order_amount", precision: 15, scale: 2, default: "0.0"
    t.date "last_order_date"
    t.boolean "late_fee_applicable", default: true
    t.string "legal_name"
    t.string "linkedin_url"
    t.boolean "mailing_address_same_as_billing", default: true
    t.boolean "marketing_emails_allowed", default: true
    t.string "mobile", limit: 20
    t.decimal "on_time_payment_rate", precision: 5, scale: 2, default: "100.0"
    t.decimal "orders_per_month", precision: 5, scale: 2, default: "0.0"
    t.bigint "organization_id"
    t.string "payment_terms", limit: 20
    t.string "phone_number"
    t.string "preferred_communication_method", limit: 20
    t.string "preferred_delivery_method", limit: 50
    t.string "primary_contact_email"
    t.string "primary_contact_name"
    t.string "primary_contact_phone", limit: 20
    t.boolean "require_po_number", default: false
    t.integer "returns_count", default: 0
    t.decimal "returns_rate", precision: 5, scale: 2, default: "0.0"
    t.string "sales_territory", limit: 50
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
    t.text "special_handling_requirements"
    t.boolean "tax_exempt", default: false
    t.string "tax_exempt_number"
    t.integer "total_orders_count", default: 0
    t.decimal "total_revenue_all_time", precision: 15, scale: 2, default: "0.0"
    t.decimal "total_revenue_mtd", precision: 15, scale: 2, default: "0.0"
    t.decimal "total_revenue_ytd", precision: 15, scale: 2, default: "0.0"
    t.string "twitter_url"
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["approved_by_id"], name: "index_customers_on_approved_by_id"
    t.index ["created_by_id"], name: "index_customers_on_created_by_id"
    t.index ["credit_hold"], name: "index_customers_on_credit_hold"
    t.index ["customer_category"], name: "index_customers_on_customer_category"
    t.index ["customer_since"], name: "index_customers_on_customer_since"
    t.index ["default_ar_account_id"], name: "index_customers_on_default_ar_account_id"
    t.index ["default_tax_code_id"], name: "index_customers_on_default_tax_code_id"
    t.index ["industry_type"], name: "index_customers_on_industry_type"
    t.index ["is_active", "deleted"], name: "index_customers_on_is_active_and_deleted"
    t.index ["last_modified_by_id"], name: "index_customers_on_last_modified_by_id"
    t.index ["last_order_date"], name: "index_customers_on_last_order_date"
    t.index ["on_time_payment_rate"], name: "index_customers_on_on_time_payment_rate"
    t.index ["organization_id"], name: "index_customers_on_organization_id"
    t.index ["sales_territory"], name: "index_customers_on_sales_territory"
    t.index ["total_revenue_all_time"], name: "index_customers_on_total_revenue_all_time"
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
    t.bigint "organization_id"
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
    t.index ["organization_id"], name: "index_cycle_counts_on_organization_id"
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
    t.bigint "organization_id"
    t.bigint "product_id", null: false
    t.decimal "qty", precision: 14, scale: 4, default: "0.0", null: false
    t.decimal "unit_cost", precision: 15, scale: 4
    t.bigint "uom_id", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_goods_receipt_lines_on_batch_id"
    t.index ["goods_receipt_id", "product_id"], name: "index_goods_receipt_lines_on_goods_receipt_id_and_product_id"
    t.index ["goods_receipt_id"], name: "index_goods_receipt_lines_on_goods_receipt_id"
    t.index ["location_id"], name: "index_goods_receipt_lines_on_location_id"
    t.index ["organization_id"], name: "index_goods_receipt_lines_on_organization_id"
    t.index ["product_id"], name: "index_goods_receipt_lines_on_product_id"
    t.index ["uom_id"], name: "index_goods_receipt_lines_on_uom_id"
  end

  create_table "goods_receipts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.boolean "deleted", default: false, null: false
    t.text "notes"
    t.bigint "organization_id"
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
    t.index ["organization_id"], name: "index_goods_receipts_on_organization_id"
    t.index ["posted_by_id"], name: "index_goods_receipts_on_posted_by_id"
    t.index ["purchase_order_id"], name: "index_goods_receipts_on_purchase_order_id"
    t.index ["reference_no"], name: "index_goods_receipts_on_reference_no", unique: true
    t.index ["status"], name: "index_goods_receipts_on_status"
    t.index ["supplier_id"], name: "index_goods_receipts_on_supplier_id"
    t.index ["warehouse_id", "status"], name: "index_goods_receipts_on_warehouse_id_and_status"
    t.index ["warehouse_id"], name: "index_goods_receipts_on_warehouse_id"
  end

  create_table "item_planning_parameters", force: :cascade do |t|
    t.string "abc_classification", limit: 1
    t.decimal "annual_demand", precision: 14, scale: 4
    t.decimal "carrying_cost_percent", precision: 5, scale: 2
    t.boolean "consider_work_calendar", default: false
    t.boolean "create_planned_pos", default: true
    t.boolean "create_planned_wos", default: true
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.decimal "fixed_order_quantity", precision: 14, scale: 4
    t.boolean "include_in_mrp", default: true
    t.boolean "is_active", default: true
    t.boolean "is_critical_item", default: false
    t.boolean "is_phantom_item", default: false
    t.string "lot_sizing_rule", limit: 30, default: "LOT_FOR_LOT"
    t.string "make_or_buy", limit: 20, default: "BUY"
    t.integer "manufacturing_lead_time_days", default: 0
    t.decimal "maximum_order_quantity", precision: 14, scale: 4
    t.decimal "maximum_stock_level", precision: 14, scale: 4, default: "0.0"
    t.decimal "minimum_order_quantity", precision: 14, scale: 4, default: "1.0"
    t.decimal "minimum_stock_level", precision: 14, scale: 4, default: "0.0"
    t.bigint "mrp_planner_id"
    t.text "notes"
    t.decimal "order_multiple", precision: 14, scale: 4, default: "1.0"
    t.decimal "ordering_cost_per_order", precision: 10, scale: 2
    t.bigint "organization_id", null: false
    t.integer "periods_of_supply", default: 1
    t.integer "planning_horizon_days", default: 90
    t.string "planning_method", limit: 30, default: "MRP", null: false
    t.integer "planning_time_fence_days", default: 7
    t.bigint "product_id", null: false
    t.integer "purchasing_lead_time_days", default: 0
    t.decimal "reorder_point", precision: 14, scale: 4, default: "0.0"
    t.integer "safety_lead_time_days", default: 0
    t.decimal "safety_stock_quantity", precision: 14, scale: 4, default: "0.0"
    t.decimal "shrinkage_percent", precision: 5, scale: 2, default: "0.0"
    t.string "time_bucket", limit: 20, default: "DAILY"
    t.datetime "updated_at", null: false
    t.string "xyz_classification", limit: 1
    t.decimal "yield_percent", precision: 5, scale: 2, default: "100.0"
    t.index ["abc_classification"], name: "index_item_planning_parameters_on_abc_classification"
    t.index ["deleted"], name: "index_item_planning_parameters_on_deleted"
    t.index ["include_in_mrp"], name: "index_item_planning_parameters_on_include_in_mrp"
    t.index ["is_critical_item"], name: "index_item_planning_parameters_on_is_critical_item"
    t.index ["mrp_planner_id"], name: "index_item_planning_parameters_on_mrp_planner_id"
    t.index ["organization_id", "product_id"], name: "idx_item_planning_params_org_product_unique", unique: true, where: "(deleted = false)"
    t.index ["organization_id"], name: "index_item_planning_parameters_on_organization_id"
    t.index ["planning_method"], name: "index_item_planning_parameters_on_planning_method"
    t.index ["product_id"], name: "index_item_planning_parameters_on_product_id"
  end

  create_table "journal_entries", force: :cascade do |t|
    t.string "accounting_period"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.text "description"
    t.date "entry_date"
    t.string "entry_number"
    t.boolean "is_reversal", default: false
    t.bigint "organization_id"
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
    t.index ["organization_id"], name: "index_journal_entries_on_organization_id"
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

  create_table "labor_time_entries", force: :cascade do |t|
    t.datetime "clock_in_at", null: false
    t.datetime "clock_out_at"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.string "entry_type", default: "REGULAR"
    t.decimal "hours_worked", precision: 10, scale: 4, default: "0.0"
    t.text "notes"
    t.bigint "operator_id", null: false
    t.bigint "organization_id"
    t.datetime "updated_at", null: false
    t.bigint "work_order_operation_id", null: false
    t.index ["clock_in_at"], name: "index_labor_time_entries_on_clock_in_at"
    t.index ["clock_out_at"], name: "index_labor_time_entries_on_clock_out_at"
    t.index ["deleted"], name: "index_labor_time_entries_on_deleted"
    t.index ["operator_id", "clock_in_at"], name: "index_labor_time_entries_on_operator_id_and_clock_in_at"
    t.index ["operator_id"], name: "index_labor_time_entries_on_operator_id"
    t.index ["organization_id"], name: "index_labor_time_entries_on_organization_id"
    t.index ["work_order_operation_id", "operator_id"], name: "index_labor_entries_on_operation_and_operator"
    t.index ["work_order_operation_id"], name: "index_labor_time_entries_on_work_order_operation_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.boolean "is_pickable"
    t.boolean "is_receivable"
    t.string "location_type", default: "GENERAL"
    t.string "name"
    t.bigint "organization_id"
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id", null: false
    t.index ["location_type"], name: "index_locations_on_location_type"
    t.index ["organization_id"], name: "index_locations_on_organization_id"
    t.index ["warehouse_id"], name: "index_locations_on_warehouse_id"
  end

  create_table "mrp_action_messages", force: :cascade do |t|
    t.datetime "acknowledged_at"
    t.string "action_category", limit: 30
    t.string "action_message_number", limit: 50, null: false
    t.date "action_required_by"
    t.string "action_type", limit: 30, null: false
    t.date "actual_new_date"
    t.decimal "actual_new_quantity", precision: 14, scale: 4
    t.jsonb "alternative_actions", default: []
    t.datetime "approved_at"
    t.bigint "assigned_to_id"
    t.boolean "auto_executed", default: false
    t.datetime "auto_executed_at"
    t.boolean "auto_expired", default: false
    t.text "business_impact"
    t.jsonb "calculation_details", default: {}
    t.boolean "can_auto_execute", default: false
    t.datetime "cancelled_at"
    t.string "constraints", default: [], array: true
    t.string "cost_impact_type", limit: 30
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "USD"
    t.date "current_date"
    t.decimal "current_quantity", precision: 14, scale: 4
    t.string "current_status", limit: 30
    t.bigint "customer_id"
    t.boolean "customer_notified", default: false
    t.datetime "customer_notified_at"
    t.integer "days_to_expedite"
    t.integer "days_until_deadline"
    t.boolean "deleted", default: false, null: false
    t.text "detailed_explanation"
    t.decimal "estimated_cost_impact", precision: 15, scale: 2
    t.datetime "executed_at"
    t.bigint "executed_by_id"
    t.text "execution_notes"
    t.text "feasibility_notes"
    t.boolean "has_child_actions", default: false
    t.text "internal_notes"
    t.boolean "is_feasible", default: true
    t.boolean "is_recurring", default: false
    t.jsonb "metadata", default: {}
    t.bigint "mrp_run_id", null: false
    t.text "notes"
    t.string "notification_recipients", default: [], array: true
    t.boolean "notification_sent", default: false
    t.datetime "notification_sent_at"
    t.integer "occurrence_count", default: 1
    t.string "order_number", limit: 50
    t.string "order_type", limit: 30
    t.bigint "organization_id", null: false
    t.bigint "parent_action_id"
    t.bigint "planned_purchase_order_id"
    t.bigint "planned_work_order_id"
    t.string "priority", limit: 20, default: "NORMAL", null: false
    t.integer "priority_score", default: 50
    t.bigint "product_id"
    t.bigint "purchase_order_id"
    t.decimal "quantity_change", precision: 14, scale: 4
    t.text "reason", null: false
    t.datetime "rejected_at"
    t.text "rejection_reason"
    t.boolean "requires_customer_notification", default: false
    t.boolean "requires_immediate_action", default: false
    t.boolean "requires_supplier_approval", default: false
    t.datetime "reviewed_at"
    t.string "status", limit: 30, default: "OPEN", null: false
    t.date "suggested_date"
    t.decimal "suggested_quantity", precision: 14, scale: 4
    t.bigint "supplier_id"
    t.boolean "supplier_notified", default: false
    t.datetime "supplier_notified_at"
    t.string "tags", default: [], array: true
    t.datetime "updated_at", null: false
    t.date "valid_until"
    t.bigint "work_order_id"
    t.index ["action_message_number"], name: "index_mrp_action_messages_on_action_message_number", unique: true
    t.index ["action_type"], name: "index_mrp_action_messages_on_action_type"
    t.index ["assigned_to_id", "status"], name: "index_mrp_action_messages_on_assigned_to_id_and_status"
    t.index ["assigned_to_id"], name: "index_mrp_action_messages_on_assigned_to_id"
    t.index ["can_auto_execute"], name: "index_mrp_action_messages_on_can_auto_execute"
    t.index ["customer_id"], name: "index_mrp_action_messages_on_customer_id"
    t.index ["deleted"], name: "index_mrp_action_messages_on_deleted"
    t.index ["executed_by_id"], name: "index_mrp_action_messages_on_executed_by_id"
    t.index ["mrp_run_id", "action_type"], name: "index_mrp_action_messages_on_mrp_run_id_and_action_type"
    t.index ["mrp_run_id"], name: "index_mrp_action_messages_on_mrp_run_id"
    t.index ["order_type", "order_number"], name: "index_mrp_action_messages_on_order_type_and_order_number"
    t.index ["organization_id", "priority"], name: "index_mrp_action_messages_on_organization_id_and_priority"
    t.index ["organization_id", "status"], name: "index_mrp_action_messages_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_mrp_action_messages_on_organization_id"
    t.index ["parent_action_id"], name: "index_mrp_action_messages_on_parent_action_id"
    t.index ["planned_purchase_order_id"], name: "index_mrp_action_messages_on_planned_purchase_order_id"
    t.index ["planned_work_order_id"], name: "index_mrp_action_messages_on_planned_work_order_id"
    t.index ["priority"], name: "index_mrp_action_messages_on_priority"
    t.index ["product_id", "status"], name: "index_mrp_action_messages_on_product_id_and_status"
    t.index ["product_id"], name: "index_mrp_action_messages_on_product_id"
    t.index ["purchase_order_id"], name: "index_mrp_action_messages_on_purchase_order_id"
    t.index ["requires_immediate_action"], name: "index_mrp_action_messages_on_requires_immediate_action"
    t.index ["status"], name: "index_mrp_action_messages_on_status"
    t.index ["supplier_id"], name: "index_mrp_action_messages_on_supplier_id"
    t.index ["work_order_id"], name: "index_mrp_action_messages_on_work_order_id"
  end

  create_table "mrp_configurations", force: :cascade do |t|
    t.boolean "action_message_generation_enabled", default: true
    t.string "action_message_types_enabled", default: ["EXPEDITE", "DELAY", "INCREASE_QUANTITY", "DECREASE_QUANTITY", "CANCEL"], array: true
    t.string "alert_frequency", default: "DAILY_DIGEST"
    t.text "alert_recipients_emails"
    t.boolean "allow_item_level_overrides", default: true
    t.integer "approval_hierarchy_levels", default: 2
    t.integer "approval_timeout_days", default: 3
    t.boolean "auto_adjust_reorder_points_enabled", default: false
    t.boolean "auto_adjust_safety_stock_enabled", default: false
    t.boolean "auto_approve_below_threshold", default: true
    t.boolean "auto_create_rfq_for_planned_pos", default: false
    t.boolean "auto_replan_trigger_enabled", default: false
    t.boolean "auto_vendor_selection_enabled", default: false
    t.string "cost_rolling_frequency", default: "MONTHLY"
    t.decimal "cost_variance_tolerance_percent", precision: 5, scale: 2, default: "5.0"
    t.datetime "created_at", null: false
    t.boolean "critical_exception_immediate_alert", default: true
    t.boolean "daily_mrp_summary_email", default: false
    t.string "default_costing_method", default: "STANDARD_COST"
    t.string "default_lot_sizing_method", default: "LOT_FOR_LOT"
    t.integer "default_manufacturing_lead_time", default: 7
    t.decimal "default_max_order_quantity", precision: 15, scale: 3
    t.decimal "default_min_order_quantity", precision: 15, scale: 3
    t.decimal "default_order_multiple", precision: 15, scale: 3, default: "1.0"
    t.integer "default_purchase_lead_time", default: 14
    t.string "demand_aggregation_level", default: "DAILY"
    t.string "demand_priority", default: "SALES_ORDER"
    t.integer "demand_time_fence_days", default: 14
    t.decimal "demand_variability_factor", precision: 5, scale: 2, default: "1.5"
    t.boolean "email_notifications_enabled", default: true
    t.boolean "email_notifications_for_approvals", default: true
    t.decimal "eoq_holding_cost_percent", precision: 5, scale: 2, default: "10.0"
    t.decimal "eoq_ordering_cost", precision: 15, scale: 2, default: "50.0"
    t.boolean "exception_alerts_enabled", default: true
    t.integer "exception_threshold_days", default: 3
    t.string "exception_types_to_monitor", default: ["MATERIAL_SHORTAGE", "LATE_POS", "LATE_WOS", "EXCESS_INVENTORY"], array: true
    t.string "forecast_consumption_method", default: "FORWARD"
    t.integer "forecast_time_fence_days", default: 30
    t.integer "frozen_zone_days", default: 7
    t.boolean "include_existing_pos_in_mrp", default: true
    t.boolean "include_existing_wos_in_mrp", default: true
    t.boolean "include_forecasts_in_mrp", default: true
    t.boolean "include_in_transit_inventory", default: true
    t.boolean "include_make_to_order_items", default: true
    t.boolean "include_make_to_stock_items", default: true
    t.boolean "include_reserved_inventory", default: false
    t.boolean "include_sales_orders_in_mrp", default: true
    t.string "inventory_allocation_method", default: "FIFO"
    t.string "item_override_settings", default: ["LOT_SIZING_RULE", "SAFETY_STOCK", "REORDER_POINT", "LEAD_TIMES"], array: true
    t.decimal "labor_overhead_rate_percent", precision: 5, scale: 2, default: "15.0"
    t.integer "lead_time_safety_buffer_days", default: 2
    t.decimal "lead_time_variability_factor", precision: 5, scale: 2, default: "1.2"
    t.integer "long_term_horizon_days", default: 90
    t.string "lot_sizing_rounding_rule", default: "UP"
    t.decimal "material_overhead_rate_percent", precision: 5, scale: 2, default: "10.0"
    t.integer "medium_term_horizon_days", default: 60
    t.integer "minimum_vendors_to_compare", default: 3
    t.string "mrp_processing_priority", default: "CRITICAL_ITEMS_FIRST"
    t.string "mrp_replanning_frequency", default: "WEEKLY"
    t.string "mrp_run_mode", default: "NET_CHANGE"
    t.boolean "notify_on_exceptions", default: true
    t.boolean "notify_on_planned_po_creation", default: true
    t.boolean "notify_on_planned_wo_creation", default: true
    t.boolean "notify_on_po_approval", default: true
    t.boolean "notify_on_vendor_quote_received", default: true
    t.bigint "organization_id", null: false
    t.string "overhead_allocation_method", default: "DIRECT_LABOR"
    t.integer "pegging_depth_level", default: 5
    t.integer "planned_order_firm_time_fence_days", default: 7
    t.decimal "planned_po_approval_threshold", precision: 15, scale: 2, default: "10000.0"
    t.boolean "planned_po_requires_approval", default: true
    t.boolean "planned_wo_requires_approval", default: false
    t.boolean "planning_calendar_working_days_only", default: true
    t.integer "planning_horizon_days", default: 90
    t.integer "planning_time_fence_days", default: 30
    t.decimal "price_tolerance_percent", precision: 5, scale: 2, default: "5.0"
    t.integer "reorder_point_alert_threshold_days", default: 3
    t.decimal "reorder_point_buffer_percent", precision: 5, scale: 2, default: "10.0"
    t.string "reorder_point_calculation_method", default: "LEAD_TIME_DEMAND"
    t.string "reorder_point_review_frequency", default: "MONTHLY"
    t.boolean "rfq_auto_send_to_vendors", default: false
    t.string "safety_stock_calculation_method", default: "DAYS_OF_SUPPLY"
    t.integer "safety_stock_days", default: 7
    t.string "safety_stock_review_frequency", default: "MONTHLY"
    t.decimal "service_level_target_percent", precision: 5, scale: 2, default: "95.0"
    t.integer "short_term_horizon_days", default: 30
    t.datetime "updated_at", null: false
    t.decimal "vendor_delivery_weight_percent", precision: 5, scale: 2, default: "30.0"
    t.decimal "vendor_price_weight_percent", precision: 5, scale: 2, default: "40.0"
    t.decimal "vendor_quality_weight_percent", precision: 5, scale: 2, default: "30.0"
    t.string "vendor_selection_criteria", default: "LOWEST_COST"
    t.boolean "weekly_planning_report", default: true
    t.index ["organization_id"], name: "index_mrp_configurations_on_organization_id", unique: true
  end

  create_table "mrp_demands", force: :cascade do |t|
    t.decimal "consumed_quantity", precision: 14, scale: 4, default: "0.0"
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.string "customer_po_number", limit: 100
    t.boolean "deleted", default: false
    t.boolean "is_active", default: true
    t.boolean "is_firm", default: false
    t.jsonb "metadata", default: {}
    t.bigint "mrp_run_id", null: false
    t.bigint "organization_id", null: false
    t.string "priority", limit: 20, default: "NORMAL"
    t.integer "priority_score", default: 50
    t.bigint "product_id", null: false
    t.decimal "quantity", precision: 14, scale: 4, null: false
    t.decimal "remaining_quantity", precision: 14, scale: 4
    t.date "required_date", null: false
    t.bigint "source_id"
    t.string "source_reference", limit: 100
    t.string "source_type", limit: 50, null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_mrp_demands_on_customer_id"
    t.index ["deleted"], name: "index_mrp_demands_on_deleted"
    t.index ["is_firm"], name: "index_mrp_demands_on_is_firm"
    t.index ["mrp_run_id", "product_id"], name: "index_mrp_demands_on_mrp_run_id_and_product_id"
    t.index ["mrp_run_id"], name: "index_mrp_demands_on_mrp_run_id"
    t.index ["organization_id", "product_id", "required_date"], name: "idx_on_organization_id_product_id_required_date_bba80bafde"
    t.index ["organization_id"], name: "index_mrp_demands_on_organization_id"
    t.index ["product_id"], name: "index_mrp_demands_on_product_id"
    t.index ["required_date"], name: "index_mrp_demands_on_required_date"
    t.index ["source_type", "source_id"], name: "index_mrp_demands_on_source_type_and_source_id"
  end

  create_table "mrp_exceptions", force: :cascade do |t|
    t.datetime "acknowledged_at"
    t.string "action_required", limit: 50
    t.date "action_required_by"
    t.datetime "assigned_at"
    t.bigint "assigned_to_id"
    t.decimal "available_quantity", precision: 14, scale: 4
    t.datetime "closed_at"
    t.text "comments"
    t.boolean "create_alert", default: false
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "USD"
    t.date "current_date"
    t.bigint "customer_id"
    t.string "customer_impact", limit: 50
    t.integer "days_early"
    t.integer "days_late"
    t.boolean "deleted", default: false, null: false
    t.text "detailed_description"
    t.datetime "detected_at", null: false
    t.decimal "estimated_cost_impact", precision: 15, scale: 2
    t.decimal "estimated_revenue_risk", precision: 15, scale: 2
    t.string "exception_category", limit: 30
    t.jsonb "exception_data", default: {}
    t.date "exception_date"
    t.text "exception_message", null: false
    t.string "exception_number", limit: 50, null: false
    t.string "exception_type", limit: 50, null: false
    t.decimal "excess_quantity", precision: 14, scale: 4
    t.date "first_occurrence_date"
    t.text "impact_analysis"
    t.boolean "is_recurring", default: false
    t.date "last_occurrence_date"
    t.jsonb "metadata", default: {}
    t.bigint "mrp_run_id", null: false
    t.string "notification_recipients", default: [], array: true
    t.boolean "notification_sent", default: false
    t.datetime "notification_sent_at"
    t.integer "occurrence_count", default: 1
    t.bigint "organization_id", null: false
    t.string "priority", limit: 20, default: "NORMAL"
    t.bigint "product_id"
    t.text "recommended_action"
    t.bigint "related_exception_id"
    t.bigint "related_planned_po_id"
    t.bigint "related_planned_wo_id"
    t.bigint "related_purchase_order_id"
    t.bigint "related_work_order_id"
    t.date "required_date"
    t.decimal "required_quantity", precision: 14, scale: 4
    t.boolean "requires_immediate_action", default: false
    t.text "resolution_action_taken"
    t.text "resolution_notes"
    t.string "resolution_type", limit: 50
    t.datetime "resolved_at"
    t.bigint "resolved_by_id"
    t.boolean "send_email", default: false
    t.boolean "send_sms", default: false
    t.string "severity", limit: 20, default: "MEDIUM", null: false
    t.integer "severity_score", default: 50
    t.decimal "shortage_quantity", precision: 14, scale: 4
    t.string "status", limit: 30, default: "OPEN", null: false
    t.string "tags", default: [], array: true
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id", "status"], name: "index_mrp_exceptions_on_assigned_to_id_and_status"
    t.index ["assigned_to_id"], name: "index_mrp_exceptions_on_assigned_to_id"
    t.index ["customer_id"], name: "index_mrp_exceptions_on_customer_id"
    t.index ["deleted"], name: "index_mrp_exceptions_on_deleted"
    t.index ["exception_category", "status"], name: "index_mrp_exceptions_on_exception_category_and_status"
    t.index ["exception_date"], name: "index_mrp_exceptions_on_exception_date"
    t.index ["exception_number"], name: "index_mrp_exceptions_on_exception_number", unique: true
    t.index ["exception_type"], name: "index_mrp_exceptions_on_exception_type"
    t.index ["is_recurring"], name: "index_mrp_exceptions_on_is_recurring"
    t.index ["mrp_run_id", "exception_type"], name: "index_mrp_exceptions_on_mrp_run_id_and_exception_type"
    t.index ["mrp_run_id"], name: "index_mrp_exceptions_on_mrp_run_id"
    t.index ["organization_id", "severity"], name: "index_mrp_exceptions_on_organization_id_and_severity"
    t.index ["organization_id", "status"], name: "index_mrp_exceptions_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_mrp_exceptions_on_organization_id"
    t.index ["product_id", "status"], name: "index_mrp_exceptions_on_product_id_and_status"
    t.index ["product_id"], name: "index_mrp_exceptions_on_product_id"
    t.index ["related_exception_id"], name: "index_mrp_exceptions_on_related_exception_id"
    t.index ["related_planned_po_id"], name: "index_mrp_exceptions_on_related_planned_po_id"
    t.index ["related_planned_wo_id"], name: "index_mrp_exceptions_on_related_planned_wo_id"
    t.index ["related_purchase_order_id"], name: "index_mrp_exceptions_on_related_purchase_order_id"
    t.index ["related_work_order_id"], name: "index_mrp_exceptions_on_related_work_order_id"
    t.index ["requires_immediate_action"], name: "index_mrp_exceptions_on_requires_immediate_action"
    t.index ["resolved_by_id"], name: "index_mrp_exceptions_on_resolved_by_id"
    t.index ["severity"], name: "index_mrp_exceptions_on_severity"
    t.index ["status"], name: "index_mrp_exceptions_on_status"
  end

  create_table "mrp_runs", force: :cascade do |t|
    t.string "abc_classes", default: [], array: true
    t.integer "action_messages_generated", default: 0
    t.text "approval_notes"
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.integer "bom_levels_processed", default: 0
    t.integer "boms_exploded", default: 0
    t.integer "cancelled_planned_orders_vs_previous"
    t.datetime "completed_at"
    t.integer "component_requirements_created", default: 0
    t.jsonb "configuration_snapshot", default: {}
    t.boolean "consider_existing_pos", default: true
    t.boolean "consider_existing_wos", default: true
    t.boolean "consider_in_transit", default: true
    t.boolean "consider_on_hand_inventory", default: true
    t.datetime "created_at", null: false
    t.boolean "critical_items_only", default: false
    t.boolean "deleted", default: false, null: false
    t.integer "duration_seconds"
    t.text "error_details"
    t.text "error_message"
    t.integer "exceptions_generated", default: 0
    t.jsonb "execution_log", default: []
    t.boolean "include_forecasts", default: true
    t.boolean "include_reorder_points", default: true
    t.boolean "include_safety_stock", default: true
    t.text "item_filter_criteria"
    t.integer "items_failed", default: 0
    t.integer "items_processed", default: 0
    t.integer "items_skipped", default: 0
    t.integer "items_to_process", default: 0
    t.integer "items_with_requirements", default: 0
    t.integer "modified_planned_orders_vs_previous"
    t.integer "new_planned_orders_vs_previous"
    t.text "notes"
    t.bigint "organization_id", null: false
    t.integer "planned_pos_generated", default: 0
    t.integer "planned_wos_generated", default: 0
    t.integer "planning_horizon_days", null: false
    t.date "planning_horizon_end", null: false
    t.date "planning_horizon_start", null: false
    t.bigint "previous_run_id"
    t.jsonb "processing_errors", default: []
    t.boolean "requires_approval", default: false
    t.bigint "run_by_id", null: false
    t.text "run_description"
    t.string "run_name", limit: 200
    t.string "run_number", limit: 50, null: false
    t.string "run_type", limit: 30, default: "REGENERATIVE", null: false
    t.datetime "started_at"
    t.string "status", limit: 30, default: "PENDING", null: false
    t.string "tags", default: [], array: true
    t.decimal "total_demand_quantity", precision: 14, scale: 4, default: "0.0"
    t.integer "total_forecasts_considered", default: 0
    t.decimal "total_in_production_qty", precision: 14, scale: 4, default: "0.0"
    t.decimal "total_on_hand_inventory", precision: 14, scale: 4, default: "0.0"
    t.decimal "total_on_order_qty", precision: 14, scale: 4, default: "0.0"
    t.decimal "total_planned_po_value", precision: 15, scale: 2, default: "0.0"
    t.decimal "total_planned_wo_value", precision: 15, scale: 2, default: "0.0"
    t.integer "total_sales_orders_considered", default: 0
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_mrp_runs_on_approved_by_id"
    t.index ["deleted"], name: "index_mrp_runs_on_deleted"
    t.index ["organization_id", "created_at"], name: "index_mrp_runs_on_organization_id_and_created_at", order: { created_at: :desc }
    t.index ["organization_id"], name: "index_mrp_runs_on_organization_id"
    t.index ["previous_run_id"], name: "index_mrp_runs_on_previous_run_id"
    t.index ["run_by_id"], name: "index_mrp_runs_on_run_by_id"
    t.index ["run_number"], name: "index_mrp_runs_on_run_number", unique: true
    t.index ["run_type"], name: "index_mrp_runs_on_run_type"
    t.index ["started_at", "completed_at"], name: "index_mrp_runs_on_started_at_and_completed_at"
    t.index ["status"], name: "index_mrp_runs_on_status"
  end

  create_table "mrp_supplies", force: :cascade do |t|
    t.decimal "allocated_quantity", precision: 14, scale: 4, default: "0.0"
    t.date "available_date", null: false
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.boolean "is_allocated", default: false
    t.boolean "is_available", default: true
    t.bigint "location_id"
    t.jsonb "metadata", default: {}
    t.bigint "mrp_run_id", null: false
    t.bigint "organization_id", null: false
    t.bigint "product_id", null: false
    t.string "quality_status", limit: 30, default: "APPROVED"
    t.decimal "quantity", precision: 14, scale: 4, null: false
    t.decimal "remaining_quantity", precision: 14, scale: 4
    t.bigint "source_id"
    t.string "source_reference", limit: 100
    t.string "source_type", limit: 50, null: false
    t.bigint "supplier_id"
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id"
    t.index ["available_date"], name: "index_mrp_supplies_on_available_date"
    t.index ["deleted"], name: "index_mrp_supplies_on_deleted"
    t.index ["is_available"], name: "index_mrp_supplies_on_is_available"
    t.index ["location_id"], name: "index_mrp_supplies_on_location_id"
    t.index ["mrp_run_id", "product_id"], name: "index_mrp_supplies_on_mrp_run_id_and_product_id"
    t.index ["mrp_run_id"], name: "index_mrp_supplies_on_mrp_run_id"
    t.index ["organization_id", "product_id", "available_date"], name: "idx_on_organization_id_product_id_available_date_4079816c11"
    t.index ["organization_id"], name: "index_mrp_supplies_on_organization_id"
    t.index ["product_id"], name: "index_mrp_supplies_on_product_id"
    t.index ["source_type", "source_id"], name: "index_mrp_supplies_on_source_type_and_source_id"
    t.index ["supplier_id"], name: "index_mrp_supplies_on_supplier_id"
    t.index ["warehouse_id"], name: "index_mrp_supplies_on_warehouse_id"
  end

  create_table "organization_settings", force: :cascade do |t|
    t.string "company_name"
    t.string "country", default: "US"
    t.datetime "created_at", null: false
    t.string "currency", default: "USD"
    t.string "date_format", default: "MM/DD/YYYY"
    t.integer "fiscal_year_start_month", default: 1
    t.jsonb "holiday_list", default: []
    t.string "legal_name"
    t.string "number_format", default: "1,234.56"
    t.bigint "organization_id", null: false
    t.text "primary_address"
    t.string "tax_id"
    t.string "time_zone", default: "America/New_York"
    t.datetime "updated_at", null: false
    t.string "working_days", default: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"], array: true
    t.decimal "working_hours_per_day", precision: 4, scale: 2, default: "8.0"
    t.index ["organization_id"], name: "index_organization_settings_on_organization_id", unique: true
  end

  create_table "organizations", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.string "industry"
    t.string "name", null: false
    t.string "subdomain", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_organizations_on_active"
    t.index ["name"], name: "index_organizations_on_name"
    t.index ["subdomain"], name: "index_organizations_on_subdomain", unique: true
  end

  create_table "planned_purchase_orders", force: :cascade do |t|
    t.date "action_new_date"
    t.decimal "action_new_quantity", precision: 14, scale: 4
    t.string "action_type", limit: 30
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.datetime "assigned_at"
    t.boolean "auto_expired", default: false
    t.bigint "buyer_assigned_id"
    t.jsonb "calculation_details", default: {}
    t.text "cancellation_reason"
    t.datetime "cancelled_at"
    t.datetime "confirmed_at"
    t.boolean "confirmed_by_planner", default: false
    t.string "conversion_status", limit: 30
    t.datetime "converted_at"
    t.decimal "converted_quantity", precision: 14, scale: 4, default: "0.0"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "currency", limit: 3, default: "USD"
    t.boolean "deleted", default: false, null: false
    t.bigint "demand_source_id"
    t.string "demand_source_reference"
    t.string "demand_source_type", limit: 50
    t.decimal "estimated_total_cost", precision: 15, scale: 2
    t.decimal "estimated_unit_cost", precision: 12, scale: 2
    t.text "exception_message"
    t.string "exception_type", limit: 50
    t.date "expected_receipt_date"
    t.datetime "expired_at"
    t.decimal "gross_requirement", precision: 14, scale: 4
    t.boolean "has_action_message", default: false
    t.boolean "has_exceptions", default: false
    t.text "internal_notes"
    t.boolean "is_blanket_order", default: false
    t.boolean "is_firmed", default: false
    t.boolean "is_rush_order", default: false
    t.boolean "is_system_generated", default: true
    t.integer "lead_time_days"
    t.string "lot_sizing_rule_applied", limit: 30
    t.integer "low_level_code", default: 0
    t.jsonb "metadata", default: {}
    t.decimal "minimum_order_quantity", precision: 14, scale: 4
    t.bigint "mrp_run_id", null: false
    t.decimal "net_requirement", precision: 14, scale: 4
    t.text "notes"
    t.decimal "order_multiple", precision: 14, scale: 4
    t.bigint "organization_id", null: false
    t.string "planned_po_number", limit: 50, null: false
    t.string "priority", limit: 20, default: "NORMAL"
    t.integer "priority_score"
    t.bigint "product_id", null: false
    t.bigint "purchase_order_id"
    t.datetime "quotes_received_at"
    t.string "reference_number", limit: 100
    t.decimal "remaining_quantity", precision: 14, scale: 4
    t.date "required_date", null: false
    t.decimal "required_quantity", precision: 14, scale: 4, null: false
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.bigint "rfq_id"
    t.datetime "rfq_sent_at"
    t.bigint "sales_forecast_id"
    t.bigint "sales_order_id"
    t.string "status", limit: 30, default: "SUGGESTED", null: false
    t.string "substatus", limit: 50
    t.date "suggested_order_date", null: false
    t.decimal "suggested_order_quantity", precision: 14, scale: 4, null: false
    t.bigint "supplier_id"
    t.text "supplier_notes"
    t.string "supplier_selection_method", limit: 50
    t.text "supplier_selection_notes"
    t.bigint "uom_id"
    t.datetime "updated_at", null: false
    t.date "valid_until"
    t.bigint "work_order_id"
    t.index ["approved_by_id"], name: "index_planned_purchase_orders_on_approved_by_id"
    t.index ["buyer_assigned_id", "status"], name: "index_planned_purchase_orders_on_buyer_assigned_id_and_status"
    t.index ["buyer_assigned_id"], name: "index_planned_purchase_orders_on_buyer_assigned_id"
    t.index ["created_by_id"], name: "index_planned_purchase_orders_on_created_by_id"
    t.index ["deleted"], name: "index_planned_purchase_orders_on_deleted"
    t.index ["demand_source_type", "demand_source_id"], name: "idx_on_demand_source_type_demand_source_id_3d8f455403"
    t.index ["has_action_message"], name: "index_planned_purchase_orders_on_has_action_message"
    t.index ["has_exceptions"], name: "index_planned_purchase_orders_on_has_exceptions"
    t.index ["is_firmed"], name: "index_planned_purchase_orders_on_is_firmed"
    t.index ["mrp_run_id", "status"], name: "index_planned_purchase_orders_on_mrp_run_id_and_status"
    t.index ["mrp_run_id"], name: "index_planned_purchase_orders_on_mrp_run_id"
    t.index ["organization_id", "required_date"], name: "idx_on_organization_id_required_date_66e92f8223"
    t.index ["organization_id", "status"], name: "index_planned_purchase_orders_on_organization_id_and_status"
    t.index ["organization_id", "suggested_order_date"], name: "idx_on_organization_id_suggested_order_date_dc3cce7195"
    t.index ["organization_id"], name: "index_planned_purchase_orders_on_organization_id"
    t.index ["planned_po_number"], name: "index_planned_purchase_orders_on_planned_po_number", unique: true
    t.index ["priority"], name: "index_planned_purchase_orders_on_priority"
    t.index ["product_id", "status"], name: "index_planned_purchase_orders_on_product_id_and_status"
    t.index ["product_id"], name: "index_planned_purchase_orders_on_product_id"
    t.index ["purchase_order_id"], name: "index_planned_purchase_orders_on_purchase_order_id"
    t.index ["reviewed_by_id"], name: "index_planned_purchase_orders_on_reviewed_by_id"
    t.index ["rfq_id"], name: "index_planned_purchase_orders_on_rfq_id"
    t.index ["sales_forecast_id"], name: "index_planned_purchase_orders_on_sales_forecast_id"
    t.index ["sales_order_id"], name: "index_planned_purchase_orders_on_sales_order_id"
    t.index ["supplier_id", "status"], name: "index_planned_purchase_orders_on_supplier_id_and_status"
    t.index ["supplier_id"], name: "index_planned_purchase_orders_on_supplier_id"
    t.index ["uom_id"], name: "index_planned_purchase_orders_on_uom_id"
    t.index ["work_order_id"], name: "index_planned_purchase_orders_on_work_order_id"
  end

  create_table "planned_work_orders", force: :cascade do |t|
    t.date "action_new_completion_date"
    t.decimal "action_new_quantity", precision: 14, scale: 4
    t.date "action_new_start_date"
    t.string "action_type", limit: 30
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.boolean "auto_expired", default: false
    t.string "bom_code", limit: 50
    t.jsonb "bom_explosion_details", default: {}
    t.bigint "bom_id"
    t.integer "bom_level", default: 0
    t.string "bom_revision", limit: 20
    t.jsonb "calculation_details", default: {}
    t.text "cancellation_reason"
    t.datetime "cancelled_at"
    t.boolean "capacity_available", default: true
    t.text "capacity_constraints"
    t.integer "components_count", default: 0
    t.datetime "confirmed_at"
    t.boolean "confirmed_by_planner", default: false
    t.string "conversion_status", limit: 30
    t.datetime "converted_at"
    t.decimal "converted_quantity", precision: 14, scale: 4, default: "0.0"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "currency", limit: 3, default: "USD"
    t.bigint "customer_id"
    t.string "customer_po_number", limit: 100
    t.boolean "deleted", default: false, null: false
    t.bigint "demand_source_id"
    t.string "demand_source_reference"
    t.string "demand_source_type", limit: 50
    t.integer "estimated_duration_minutes"
    t.decimal "estimated_labor_cost", precision: 15, scale: 2
    t.decimal "estimated_material_cost", precision: 15, scale: 2
    t.decimal "estimated_overhead_cost", precision: 15, scale: 2
    t.integer "estimated_run_minutes"
    t.integer "estimated_setup_minutes"
    t.decimal "estimated_total_cost", precision: 15, scale: 2
    t.text "exception_message"
    t.string "exception_type", limit: 50
    t.datetime "expired_at"
    t.decimal "gross_requirement", precision: 14, scale: 4
    t.boolean "has_action_message", default: false
    t.boolean "has_exceptions", default: false
    t.text "internal_notes"
    t.boolean "is_firmed", default: false
    t.boolean "is_rush_order", default: false
    t.boolean "is_system_generated", default: true
    t.integer "lead_time_days"
    t.string "lot_sizing_rule_applied", limit: 30
    t.integer "low_level_code", default: 0
    t.string "make_or_buy_decision", limit: 20, default: "MAKE"
    t.text "material_shortages"
    t.boolean "materials_available", default: true
    t.jsonb "metadata", default: {}
    t.decimal "minimum_production_quantity", precision: 14, scale: 4
    t.integer "missing_materials_count", default: 0
    t.bigint "mrp_run_id", null: false
    t.decimal "net_requirement", precision: 14, scale: 4
    t.text "notes"
    t.bigint "organization_id", null: false
    t.bigint "parent_planned_wo_id"
    t.bigint "parent_work_order_id"
    t.string "planned_wo_number", limit: 50, null: false
    t.bigint "primary_work_center_id"
    t.string "priority", limit: 20, default: "NORMAL"
    t.integer "priority_score"
    t.bigint "product_id", null: false
    t.text "production_notes"
    t.bigint "production_planner_id"
    t.decimal "quantity_with_scrap", precision: 14, scale: 4
    t.string "reference_number", limit: 100
    t.decimal "remaining_quantity", precision: 14, scale: 4
    t.date "required_completion_date", null: false
    t.decimal "required_quantity", precision: 14, scale: 4, null: false
    t.boolean "requires_special_tooling", default: false
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.string "routing_code", limit: 50
    t.jsonb "routing_details", default: {}
    t.bigint "routing_id"
    t.integer "routing_lead_time_days"
    t.string "routing_revision", limit: 20
    t.bigint "sales_forecast_id"
    t.bigint "sales_order_id"
    t.decimal "scrap_allowance_percent", precision: 5, scale: 2, default: "0.0"
    t.string "status", limit: 30, default: "SUGGESTED", null: false
    t.string "substatus", limit: 50
    t.decimal "suggested_production_quantity", precision: 14, scale: 4, null: false
    t.date "suggested_release_date"
    t.date "suggested_start_date", null: false
    t.decimal "total_capacity_hours_required", precision: 10, scale: 2
    t.decimal "total_component_cost", precision: 15, scale: 2
    t.bigint "uom_id"
    t.datetime "updated_at", null: false
    t.date "valid_until"
    t.boolean "work_center_pre_assigned", default: false
    t.bigint "work_order_id"
    t.index ["approved_by_id"], name: "index_planned_work_orders_on_approved_by_id"
    t.index ["bom_id"], name: "index_planned_work_orders_on_bom_id"
    t.index ["bom_level"], name: "index_planned_work_orders_on_bom_level"
    t.index ["capacity_available"], name: "index_planned_work_orders_on_capacity_available"
    t.index ["created_by_id"], name: "index_planned_work_orders_on_created_by_id"
    t.index ["customer_id"], name: "index_planned_work_orders_on_customer_id"
    t.index ["deleted"], name: "index_planned_work_orders_on_deleted"
    t.index ["demand_source_type", "demand_source_id"], name: "idx_on_demand_source_type_demand_source_id_27c60cf9c6"
    t.index ["has_action_message"], name: "index_planned_work_orders_on_has_action_message"
    t.index ["has_exceptions"], name: "index_planned_work_orders_on_has_exceptions"
    t.index ["is_firmed"], name: "index_planned_work_orders_on_is_firmed"
    t.index ["materials_available"], name: "index_planned_work_orders_on_materials_available"
    t.index ["mrp_run_id", "status"], name: "index_planned_work_orders_on_mrp_run_id_and_status"
    t.index ["mrp_run_id"], name: "index_planned_work_orders_on_mrp_run_id"
    t.index ["organization_id", "required_completion_date"], name: "idx_on_organization_id_required_completion_date_b6daec27d7"
    t.index ["organization_id", "status"], name: "index_planned_work_orders_on_organization_id_and_status"
    t.index ["organization_id", "suggested_start_date"], name: "idx_on_organization_id_suggested_start_date_ee35c15b44"
    t.index ["organization_id"], name: "index_planned_work_orders_on_organization_id"
    t.index ["parent_planned_wo_id"], name: "index_planned_work_orders_on_parent_planned_wo_id"
    t.index ["parent_work_order_id"], name: "index_planned_work_orders_on_parent_work_order_id"
    t.index ["planned_wo_number"], name: "index_planned_work_orders_on_planned_wo_number", unique: true
    t.index ["primary_work_center_id", "status"], name: "index_planned_work_orders_on_primary_work_center_id_and_status"
    t.index ["primary_work_center_id"], name: "index_planned_work_orders_on_primary_work_center_id"
    t.index ["priority"], name: "index_planned_work_orders_on_priority"
    t.index ["product_id", "status"], name: "index_planned_work_orders_on_product_id_and_status"
    t.index ["product_id"], name: "index_planned_work_orders_on_product_id"
    t.index ["production_planner_id", "status"], name: "index_planned_work_orders_on_production_planner_id_and_status"
    t.index ["production_planner_id"], name: "index_planned_work_orders_on_production_planner_id"
    t.index ["reviewed_by_id"], name: "index_planned_work_orders_on_reviewed_by_id"
    t.index ["routing_id"], name: "index_planned_work_orders_on_routing_id"
    t.index ["sales_forecast_id"], name: "index_planned_work_orders_on_sales_forecast_id"
    t.index ["sales_order_id"], name: "index_planned_work_orders_on_sales_order_id"
    t.index ["uom_id"], name: "index_planned_work_orders_on_uom_id"
    t.index ["work_order_id"], name: "index_planned_work_orders_on_work_order_id"
  end

  create_table "product_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.string "name"
    t.bigint "organization_id"
    t.integer "parent_id"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_product_categories_on_organization_id"
    t.index ["parent_id"], name: "index_product_categories_on_parent_id"
  end

  create_table "product_suppliers", force: :cascade do |t|
    t.boolean "available_for_order", default: true
    t.decimal "average_purchase_price", precision: 15, scale: 4
    t.text "buyer_notes"
    t.date "contract_expiry_date"
    t.string "contract_reference"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.decimal "current_unit_price", precision: 15, scale: 4, null: false
    t.integer "days_since_last_order"
    t.boolean "deleted", default: false
    t.decimal "delivery_performance_rating", precision: 5, scale: 2, default: "100.0"
    t.string "discontinuation_reason"
    t.date "discontinued_date"
    t.text "engineering_notes"
    t.date "first_purchase_date"
    t.boolean "is_active", default: true
    t.boolean "is_approved_supplier", default: true
    t.boolean "is_preferred_supplier", default: false
    t.boolean "is_sole_source", default: false
    t.boolean "is_strategic_item", default: false
    t.date "last_purchase_date"
    t.decimal "last_purchase_price", precision: 15, scale: 4
    t.decimal "last_purchase_quantity", precision: 15, scale: 2
    t.date "last_quality_issue_date"
    t.integer "late_deliveries_count", default: 0
    t.integer "lead_time_days", null: false
    t.string "manufacturer_part_number"
    t.integer "maximum_order_quantity"
    t.integer "minimum_order_quantity", default: 1
    t.integer "order_multiple"
    t.bigint "organization_id"
    t.string "packaging_type"
    t.decimal "previous_unit_price", precision: 15, scale: 4
    t.decimal "price_break_1_price", precision: 15, scale: 4
    t.decimal "price_break_1_qty", precision: 15, scale: 2
    t.decimal "price_break_2_price", precision: 15, scale: 4
    t.decimal "price_break_2_qty", precision: 15, scale: 2
    t.decimal "price_break_3_price", precision: 15, scale: 4
    t.decimal "price_break_3_qty", precision: 15, scale: 2
    t.decimal "price_change_percentage", precision: 5, scale: 2
    t.date "price_effective_date"
    t.date "price_expiry_date"
    t.string "price_trend"
    t.string "price_uom"
    t.bigint "product_id", null: false
    t.integer "quality_issues_count", default: 0
    t.text "quality_notes"
    t.decimal "quality_rating", precision: 5, scale: 2, default: "100.0"
    t.text "quality_requirements"
    t.string "replacement_product_code"
    t.boolean "requires_coc", default: false
    t.boolean "requires_msds", default: false
    t.boolean "requires_quality_cert", default: false
    t.string "sourcing_strategy"
    t.bigint "supplier_id", null: false
    t.string "supplier_item_code"
    t.string "supplier_item_description"
    t.integer "supplier_rank"
    t.text "technical_specifications"
    t.text "testing_requirements"
    t.integer "total_orders_count", default: 0
    t.decimal "total_quantity_purchased", precision: 15, scale: 2, default: "0.0"
    t.decimal "total_value_purchased", precision: 15, scale: 2, default: "0.0"
    t.integer "units_per_package"
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["created_by_id"], name: "index_product_suppliers_on_created_by_id"
    t.index ["current_unit_price"], name: "index_product_suppliers_on_current_unit_price"
    t.index ["is_active"], name: "index_product_suppliers_on_is_active"
    t.index ["is_approved_supplier"], name: "index_product_suppliers_on_is_approved_supplier"
    t.index ["is_preferred_supplier"], name: "index_product_suppliers_on_is_preferred_supplier"
    t.index ["lead_time_days"], name: "index_product_suppliers_on_lead_time_days"
    t.index ["organization_id"], name: "index_product_suppliers_on_organization_id"
    t.index ["product_id", "supplier_id"], name: "index_product_suppliers_on_product_id_and_supplier_id", unique: true
    t.index ["product_id"], name: "index_product_suppliers_on_product_id"
    t.index ["quality_rating"], name: "index_product_suppliers_on_quality_rating"
    t.index ["supplier_id"], name: "index_product_suppliers_on_supplier_id"
    t.index ["supplier_item_code"], name: "index_product_suppliers_on_supplier_item_code"
    t.index ["supplier_rank"], name: "index_product_suppliers_on_supplier_rank"
    t.index ["updated_by_id"], name: "index_product_suppliers_on_updated_by_id"
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.text "description"
    t.boolean "is_active"
    t.boolean "is_batch_tracked"
    t.boolean "is_serial_tracked"
    t.boolean "is_stocked"
    t.string "name"
    t.bigint "organization_id"
    t.integer "product_category_id"
    t.string "product_type"
    t.decimal "reorder_point"
    t.string "sku"
    t.decimal "standard_cost"
    t.integer "unit_of_measure_id"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_products_on_organization_id"
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
    t.bigint "organization_id"
    t.bigint "product_id", null: false
    t.bigint "purchase_order_id", null: false
    t.decimal "received_qty", precision: 14, scale: 4, default: "0.0"
    t.bigint "rfq_item_id"
    t.decimal "tax_amount", precision: 15, scale: 2, default: "0.0"
    t.bigint "tax_code_id"
    t.decimal "tax_rate", precision: 6, scale: 4, default: "0.0"
    t.decimal "unit_price", precision: 15, scale: 4, default: "0.0", null: false
    t.bigint "uom_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "vendor_quote_id"
    t.index ["line_status"], name: "index_purchase_order_lines_on_line_status"
    t.index ["organization_id"], name: "index_purchase_order_lines_on_organization_id"
    t.index ["product_id"], name: "index_purchase_order_lines_on_product_id"
    t.index ["purchase_order_id"], name: "index_purchase_order_lines_on_purchase_order_id"
    t.index ["rfq_item_id"], name: "index_purchase_order_lines_on_rfq_item_id"
    t.index ["tax_code_id"], name: "index_purchase_order_lines_on_tax_code_id"
    t.index ["uom_id"], name: "index_purchase_order_lines_on_uom_id"
    t.index ["vendor_quote_id"], name: "index_purchase_order_lines_on_vendor_quote_id"
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
    t.bigint "organization_id"
    t.string "payment_terms", limit: 50
    t.string "po_number", limit: 50, null: false
    t.bigint "rfq_id"
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
    t.index ["organization_id"], name: "index_purchase_orders_on_organization_id"
    t.index ["po_number"], name: "index_purchase_orders_on_po_number", unique: true
    t.index ["rfq_id"], name: "index_purchase_orders_on_rfq_id"
    t.index ["status"], name: "index_purchase_orders_on_status"
    t.index ["supplier_id", "status"], name: "index_purchase_orders_on_supplier_id_and_status"
    t.index ["supplier_id"], name: "index_purchase_orders_on_supplier_id"
    t.index ["warehouse_id"], name: "index_purchase_orders_on_warehouse_id"
  end

  create_table "rfq_items", force: :cascade do |t|
    t.decimal "average_quoted_price", precision: 15, scale: 4
    t.datetime "awarded_at"
    t.integer "best_delivery_days"
    t.text "buyer_notes"
    t.string "color_specification"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "criticality_reason"
    t.string "customer_part_number"
    t.string "delivery_location"
    t.text "dimensional_requirements"
    t.string "drawing_number"
    t.integer "drawing_revision"
    t.text "engineering_notes"
    t.string "finish_requirement"
    t.decimal "highest_quoted_price", precision: 15, scale: 4
    t.boolean "is_critical_item", default: false
    t.boolean "is_custom_fabrication", default: false
    t.boolean "is_long_lead_item", default: false
    t.string "item_description"
    t.date "last_purchase_date"
    t.decimal "last_purchase_price", precision: 15, scale: 4
    t.bigint "last_purchased_from_id"
    t.integer "line_number", null: false
    t.decimal "lowest_quoted_price", precision: 15, scale: 4
    t.string "material_grade"
    t.bigint "organization_id"
    t.text "packaging_requirements"
    t.boolean "partial_delivery_acceptable", default: false
    t.decimal "price_variance_percentage", precision: 5, scale: 2
    t.decimal "price_variance_vs_last", precision: 15, scale: 2
    t.decimal "price_variance_vs_target", precision: 15, scale: 2
    t.bigint "product_id", null: false
    t.text "quality_notes"
    t.text "quality_requirements"
    t.decimal "quantity_requested", precision: 15, scale: 2, null: false
    t.integer "quotes_received_count", default: 0
    t.text "reference_notes"
    t.date "required_delivery_date"
    t.boolean "requires_approval", default: false
    t.boolean "requires_testing", default: false
    t.bigint "rfq_id", null: false
    t.decimal "savings_vs_highest_quote", precision: 15, scale: 2
    t.integer "selected_lead_time_days"
    t.bigint "selected_supplier_id"
    t.decimal "selected_total_price", precision: 15, scale: 2
    t.decimal "selected_unit_price", precision: 15, scale: 4
    t.text "selection_reason"
    t.text "shipping_instructions"
    t.decimal "target_total_price", precision: 15, scale: 2
    t.decimal "target_unit_price", precision: 15, scale: 4
    t.text "technical_specifications"
    t.string "testing_standards"
    t.string "unit_of_measure"
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["created_by_id"], name: "index_rfq_items_on_created_by_id"
    t.index ["is_critical_item"], name: "index_rfq_items_on_is_critical_item"
    t.index ["last_purchased_from_id"], name: "index_rfq_items_on_last_purchased_from_id"
    t.index ["organization_id"], name: "index_rfq_items_on_organization_id"
    t.index ["product_id"], name: "index_rfq_items_on_product_id"
    t.index ["required_delivery_date"], name: "index_rfq_items_on_required_delivery_date"
    t.index ["rfq_id", "line_number"], name: "index_rfq_items_on_rfq_id_and_line_number", unique: true
    t.index ["rfq_id"], name: "index_rfq_items_on_rfq_id"
    t.index ["selected_supplier_id"], name: "index_rfq_items_on_selected_supplier_id"
    t.index ["updated_by_id"], name: "index_rfq_items_on_updated_by_id"
  end

  create_table "rfq_suppliers", force: :cascade do |t|
    t.string "contact_email_used"
    t.datetime "created_at", null: false
    t.integer "days_overdue"
    t.text "decline_reason"
    t.datetime "declined_at"
    t.boolean "email_bounced", default: false
    t.integer "email_count", default: 0
    t.text "internal_notes"
    t.string "invitation_status", default: "INVITED"
    t.datetime "invited_at"
    t.bigint "invited_by_id"
    t.boolean "is_selected", default: false
    t.integer "items_not_quoted_count", default: 0
    t.integer "items_quoted_count", default: 0
    t.datetime "last_email_sent_at"
    t.bigint "organization_id"
    t.boolean "quoted_all_items", default: false
    t.datetime "quoted_at"
    t.boolean "responded_on_time", default: true
    t.integer "response_time_hours"
    t.bigint "rfq_id", null: false
    t.date "selected_date"
    t.text "selection_notes"
    t.bigint "supplier_contact_id"
    t.bigint "supplier_id", null: false
    t.decimal "total_quoted_amount", precision: 15, scale: 2
    t.datetime "updated_at", null: false
    t.datetime "viewed_at"
    t.index ["invitation_status"], name: "index_rfq_suppliers_on_invitation_status"
    t.index ["invited_at"], name: "index_rfq_suppliers_on_invited_at"
    t.index ["invited_by_id"], name: "index_rfq_suppliers_on_invited_by_id"
    t.index ["is_selected"], name: "index_rfq_suppliers_on_is_selected"
    t.index ["organization_id"], name: "index_rfq_suppliers_on_organization_id"
    t.index ["rfq_id", "supplier_id"], name: "index_rfq_suppliers_on_rfq_id_and_supplier_id", unique: true
    t.index ["rfq_id"], name: "index_rfq_suppliers_on_rfq_id"
    t.index ["supplier_contact_id"], name: "index_rfq_suppliers_on_supplier_contact_id"
    t.index ["supplier_id"], name: "index_rfq_suppliers_on_supplier_id"
  end

  create_table "rfqs", force: :cascade do |t|
    t.date "all_responses_received_date"
    t.text "approval_notes"
    t.datetime "approved_at"
    t.bigint "approver_id"
    t.text "attachments_description"
    t.boolean "auto_email_enabled", default: true
    t.decimal "average_quote_amount", precision: 15, scale: 2
    t.date "award_date"
    t.text "award_reason"
    t.bigint "awarded_supplier_id"
    t.decimal "awarded_total_amount", precision: 15, scale: 2
    t.bigint "buyer_assigned_id"
    t.text "buyer_notes"
    t.text "cancellation_reason"
    t.datetime "cancelled_at"
    t.integer "cancelled_by_id"
    t.datetime "closed_at"
    t.string "comparison_basis"
    t.integer "comparison_views_count", default: 0
    t.date "conversion_date", comment: "Date when RFQ was converted to PO(s)"
    t.bigint "converted_by_id", comment: "User who converted RFQ to PO"
    t.boolean "converted_to_po", default: false
    t.decimal "cost_savings", precision: 15, scale: 2
    t.decimal "cost_savings_percentage", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.integer "days_to_all_responses"
    t.integer "days_to_first_response"
    t.datetime "deleted_at"
    t.bigint "deleted_by_id"
    t.text "delivery_terms"
    t.text "description"
    t.date "due_date", null: false
    t.decimal "estimated_budget", precision: 15, scale: 2
    t.text "evaluation_notes"
    t.decimal "highest_quote_amount", precision: 15, scale: 2
    t.string "incoterms"
    t.text "internal_notes"
    t.boolean "is_deleted", default: false
    t.boolean "is_urgent", default: false
    t.datetime "last_compared_at"
    t.datetime "last_reminder_sent_at"
    t.decimal "lowest_quote_amount", precision: 15, scale: 2
    t.bigint "organization_id"
    t.text "payment_terms"
    t.date "po_created_date"
    t.string "po_numbers", comment: "Comma-separated list of generated PO numbers"
    t.string "priority", default: "NORMAL"
    t.text "quality_requirements"
    t.integer "quotes_pending_count", default: 0
    t.integer "quotes_received_count", default: 0
    t.bigint "recommended_supplier_id"
    t.decimal "recommended_supplier_score", precision: 5, scale: 2
    t.integer "reminder_count", default: 0
    t.bigint "requester_id"
    t.date "required_delivery_date"
    t.boolean "requires_certifications", default: false
    t.boolean "requires_samples", default: false
    t.boolean "requires_technical_drawings", default: false
    t.date "response_deadline"
    t.decimal "response_rate_percentage", precision: 5, scale: 2
    t.date "rfq_date", null: false
    t.string "rfq_number", null: false
    t.jsonb "scoring_weights"
    t.decimal "selected_quote_amount", precision: 15, scale: 2
    t.boolean "send_to_all_contacts", default: false
    t.datetime "sent_at"
    t.text "special_instructions"
    t.string "status", default: "DRAFT", null: false
    t.integer "suppliers_invited_count", default: 0
    t.text "terms_and_conditions"
    t.string "title", null: false
    t.integer "total_items_count", default: 0
    t.decimal "total_quantity_requested", precision: 15, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["approver_id"], name: "index_rfqs_on_approver_id"
    t.index ["awarded_supplier_id"], name: "index_rfqs_on_awarded_supplier_id"
    t.index ["buyer_assigned_id"], name: "index_rfqs_on_buyer_assigned_id"
    t.index ["cancelled_by_id"], name: "index_rfqs_on_cancelled_by_id"
    t.index ["conversion_date"], name: "index_rfqs_on_conversion_date"
    t.index ["converted_by_id"], name: "index_rfqs_on_converted_by_id"
    t.index ["created_at"], name: "index_rfqs_on_created_at"
    t.index ["created_by_id"], name: "index_rfqs_on_created_by_id"
    t.index ["deleted_by_id"], name: "index_rfqs_on_deleted_by_id"
    t.index ["due_date"], name: "index_rfqs_on_due_date"
    t.index ["is_deleted"], name: "index_rfqs_on_is_deleted"
    t.index ["is_urgent"], name: "index_rfqs_on_is_urgent"
    t.index ["organization_id"], name: "index_rfqs_on_organization_id"
    t.index ["recommended_supplier_id"], name: "index_rfqs_on_recommended_supplier_id"
    t.index ["requester_id"], name: "index_rfqs_on_requester_id"
    t.index ["response_deadline"], name: "index_rfqs_on_response_deadline"
    t.index ["rfq_date"], name: "index_rfqs_on_rfq_date"
    t.index ["rfq_number"], name: "index_rfqs_on_rfq_number", unique: true
    t.index ["status", "is_deleted"], name: "index_rfqs_on_status_and_is_deleted"
    t.index ["status"], name: "index_rfqs_on_status"
    t.index ["updated_by_id"], name: "index_rfqs_on_updated_by_id"
  end

  create_table "routing_operations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.text "description"
    t.boolean "is_quality_check_required", default: false
    t.decimal "labor_cost_per_unit", precision: 12, scale: 2, default: "0.0"
    t.decimal "labor_hours_per_unit", precision: 8, scale: 4, default: "0.0"
    t.decimal "move_time_minutes", precision: 10, scale: 2, default: "0.0"
    t.text "notes"
    t.string "operation_name", limit: 100, null: false
    t.integer "operation_sequence", null: false
    t.bigint "organization_id"
    t.decimal "overhead_cost_per_unit", precision: 12, scale: 2, default: "0.0"
    t.text "quality_check_instructions"
    t.bigint "routing_id", null: false
    t.decimal "run_time_per_unit_minutes", precision: 10, scale: 2, default: "0.0"
    t.decimal "setup_time_minutes", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.decimal "wait_time_minutes", precision: 10, scale: 2, default: "0.0"
    t.bigint "work_center_id", null: false
    t.index ["organization_id"], name: "index_routing_operations_on_organization_id"
    t.index ["routing_id", "deleted"], name: "index_routing_operations_on_routing_id_and_deleted"
    t.index ["routing_id", "operation_sequence"], name: "index_routing_ops_on_routing_and_seq"
    t.index ["routing_id"], name: "index_routing_operations_on_routing_id"
    t.index ["work_center_id"], name: "index_routing_operations_on_work_center_id"
  end

  create_table "routings", force: :cascade do |t|
    t.string "code", limit: 20, null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.boolean "deleted", default: false
    t.text "description"
    t.date "effective_from", null: false
    t.date "effective_to"
    t.boolean "is_default", default: false
    t.string "name", limit: 100, null: false
    t.text "notes"
    t.bigint "organization_id"
    t.bigint "product_id", null: false
    t.string "revision", limit: 16, default: "1"
    t.string "status", limit: 20, default: "DRAFT", null: false
    t.decimal "total_labor_cost_per_unit", precision: 12, scale: 2, default: "0.0"
    t.decimal "total_overhead_cost_per_unit", precision: 12, scale: 2, default: "0.0"
    t.decimal "total_run_time_per_unit_minutes", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_setup_time_minutes", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_routings_on_code", unique: true
    t.index ["created_by_id"], name: "index_routings_on_created_by_id"
    t.index ["effective_from", "effective_to"], name: "index_routings_on_effective_from_and_effective_to"
    t.index ["organization_id"], name: "index_routings_on_organization_id"
    t.index ["product_id", "is_default"], name: "index_routings_on_product_id_and_is_default"
    t.index ["product_id", "status"], name: "index_routings_on_product_id_and_status"
    t.index ["product_id"], name: "index_routings_on_product_id"
    t.index ["status"], name: "index_routings_on_status"
  end

  create_table "sales_forecasts", force: :cascade do |t|
    t.decimal "actual_quantity", precision: 14, scale: 4, default: "0.0"
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.text "assumptions"
    t.string "confidence_category", limit: 20
    t.decimal "confidence_level", precision: 5, scale: 2, default: "100.0"
    t.decimal "consumed_quantity", precision: 14, scale: 4, default: "0.0"
    t.integer "consumption_days_backward", default: 7
    t.integer "consumption_days_forward", default: 30
    t.string "consumption_method", limit: 30, default: "FORWARD"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.bigint "customer_id"
    t.boolean "deleted", default: false, null: false
    t.string "demand_driver", limit: 100
    t.datetime "expired_at"
    t.decimal "forecast_bias", precision: 14, scale: 4
    t.decimal "forecast_error", precision: 14, scale: 4
    t.string "forecast_method", limit: 50
    t.string "forecast_name", limit: 200
    t.string "forecast_number", limit: 50, null: false
    t.string "forecast_type", limit: 30, default: "MANUAL"
    t.decimal "forecasted_quantity", precision: 14, scale: 4, null: false
    t.boolean "include_in_mrp", default: true
    t.string "market_segment", limit: 100
    t.decimal "mean_absolute_deviation", precision: 14, scale: 4
    t.jsonb "metadata", default: {}
    t.integer "month"
    t.text "notes"
    t.bigint "organization_id", null: false
    t.date "period_end_date", null: false
    t.date "period_start_date", null: false
    t.string "period_type", limit: 20, default: "MONTHLY", null: false
    t.bigint "product_id", null: false
    t.integer "quarter"
    t.decimal "remaining_quantity", precision: 14, scale: 4
    t.integer "revision_number", default: 1
    t.string "sales_channel", limit: 100
    t.decimal "standard_deviation", precision: 14, scale: 4
    t.string "status", limit: 30, default: "DRAFT"
    t.datetime "submitted_at"
    t.bigint "superseded_by_id"
    t.datetime "updated_at", null: false
    t.string "version", limit: 20, default: "V1"
    t.integer "week"
    t.integer "year", null: false
    t.index ["approved_by_id"], name: "index_sales_forecasts_on_approved_by_id"
    t.index ["created_by_id"], name: "index_sales_forecasts_on_created_by_id"
    t.index ["customer_id"], name: "index_sales_forecasts_on_customer_id"
    t.index ["deleted"], name: "index_sales_forecasts_on_deleted"
    t.index ["forecast_number"], name: "index_sales_forecasts_on_forecast_number", unique: true
    t.index ["include_in_mrp"], name: "index_sales_forecasts_on_include_in_mrp"
    t.index ["organization_id", "product_id", "period_start_date"], name: "idx_on_organization_id_product_id_period_start_date_d42659ea7b"
    t.index ["organization_id"], name: "index_sales_forecasts_on_organization_id"
    t.index ["period_start_date", "period_end_date"], name: "index_sales_forecasts_on_period_start_date_and_period_end_date"
    t.index ["product_id"], name: "index_sales_forecasts_on_product_id"
    t.index ["status"], name: "index_sales_forecasts_on_status"
    t.index ["superseded_by_id"], name: "index_sales_forecasts_on_superseded_by_id"
    t.index ["year", "month"], name: "index_sales_forecasts_on_year_and_month", where: "(month IS NOT NULL)"
    t.index ["year", "quarter"], name: "index_sales_forecasts_on_year_and_quarter", where: "(quarter IS NOT NULL)"
  end

  create_table "sales_orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "organization_id"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_sales_orders_on_organization_id"
  end

  create_table "stock_adjustment_lines", force: :cascade do |t|
    t.bigint "batch_id"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.text "line_note"
    t.text "line_reason"
    t.bigint "location_id", null: false
    t.bigint "organization_id"
    t.bigint "product_id", null: false
    t.decimal "qty_delta", precision: 14, scale: 4, default: "0.0", null: false
    t.bigint "stock_adjustment_id", null: false
    t.decimal "system_qty_at_adjustment", precision: 14, scale: 4
    t.bigint "uom_id", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_stock_adjustment_lines_on_batch_id"
    t.index ["location_id"], name: "index_stock_adjustment_lines_on_location_id"
    t.index ["organization_id"], name: "index_stock_adjustment_lines_on_organization_id"
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
    t.bigint "organization_id"
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
    t.index ["organization_id"], name: "index_stock_adjustments_on_organization_id"
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
    t.bigint "organization_id"
    t.bigint "product_id", null: false
    t.string "quality_status"
    t.string "supplier_batch_ref"
    t.string "supplier_lot_number"
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_stock_batches_on_created_by_id"
    t.index ["organization_id"], name: "index_stock_batches_on_organization_id"
    t.index ["product_id"], name: "index_stock_batches_on_product_id"
  end

  create_table "stock_issue_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.integer "from_location_id", null: false
    t.bigint "organization_id"
    t.bigint "product_id", null: false
    t.decimal "quantity"
    t.bigint "stock_batch_id"
    t.bigint "stock_issue_id", null: false
    t.datetime "updated_at", null: false
    t.index ["from_location_id"], name: "index_stock_issue_lines_on_from_location_id"
    t.index ["organization_id"], name: "index_stock_issue_lines_on_organization_id"
    t.index ["product_id"], name: "index_stock_issue_lines_on_product_id"
    t.index ["stock_batch_id"], name: "index_stock_issue_lines_on_stock_batch_id"
    t.index ["stock_issue_id"], name: "index_stock_issue_lines_on_stock_issue_id"
  end

  create_table "stock_issues", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "created_by"
    t.integer "created_by_id"
    t.boolean "deleted"
    t.bigint "organization_id"
    t.datetime "posted_at"
    t.integer "posted_by"
    t.string "reference_no"
    t.string "status"
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id", null: false
    t.index ["created_by_id"], name: "index_stock_issues_on_created_by_id"
    t.index ["organization_id"], name: "index_stock_issues_on_organization_id"
    t.index ["posted_by"], name: "index_stock_issues_on_posted_by"
    t.index ["warehouse_id"], name: "index_stock_issues_on_warehouse_id"
  end

  create_table "stock_levels", force: :cascade do |t|
    t.bigint "batch_id"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.bigint "location_id", null: false
    t.decimal "on_hand_qty", precision: 20, scale: 6, default: "0.0", null: false
    t.bigint "organization_id"
    t.bigint "product_id", null: false
    t.decimal "reserved_qty", precision: 20, scale: 6, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_stock_levels_on_batch_id"
    t.index ["location_id"], name: "index_stock_levels_on_location_id"
    t.index ["organization_id"], name: "index_stock_levels_on_organization_id"
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
    t.bigint "organization_id"
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
    t.index ["organization_id"], name: "index_stock_transactions_on_organization_id"
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
    t.bigint "organization_id"
    t.bigint "product_id", null: false
    t.decimal "qty", precision: 14, scale: 4, default: "0.0", null: false
    t.bigint "stock_transfer_id", null: false
    t.bigint "to_location_id", null: false
    t.bigint "uom_id", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_stock_transfer_lines_on_batch_id"
    t.index ["from_location_id"], name: "index_stock_transfer_lines_on_from_location_id"
    t.index ["organization_id"], name: "index_stock_transfer_lines_on_organization_id"
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
    t.bigint "organization_id"
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
    t.index ["organization_id"], name: "index_stock_transfers_on_organization_id"
    t.index ["posted_by"], name: "index_stock_transfers_on_posted_by"
    t.index ["requested_by_id"], name: "index_stock_transfers_on_requested_by_id"
    t.index ["to_warehouse_id"], name: "index_stock_transfers_on_to_warehouse_id"
    t.index ["transfer_number"], name: "index_stock_transfers_on_transfer_number", unique: true
  end

  create_table "supplier_activities", force: :cascade do |t|
    t.text "action_items"
    t.datetime "activity_date", null: false
    t.string "activity_status", default: "COMPLETED"
    t.string "activity_type", null: false
    t.text "attachments_description"
    t.string "category"
    t.string "communication_method"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "description"
    t.string "direction"
    t.integer "duration_minutes"
    t.date "followup_date"
    t.boolean "followup_required", default: false
    t.boolean "is_overdue", default: false
    t.text "next_steps"
    t.bigint "organization_id"
    t.text "outcome"
    t.string "priority", default: "NORMAL"
    t.bigint "related_record_id"
    t.string "related_record_type"
    t.bigint "related_user_id"
    t.string "subject", null: false
    t.bigint "supplier_contact_id"
    t.bigint "supplier_id", null: false
    t.string "supplier_sentiment"
    t.text "tags"
    t.datetime "updated_at", null: false
    t.index ["activity_date"], name: "index_supplier_activities_on_activity_date"
    t.index ["activity_status"], name: "index_supplier_activities_on_activity_status"
    t.index ["activity_type"], name: "index_supplier_activities_on_activity_type"
    t.index ["created_by_id"], name: "index_supplier_activities_on_created_by_id"
    t.index ["followup_date"], name: "index_supplier_activities_on_followup_date"
    t.index ["is_overdue"], name: "index_supplier_activities_on_is_overdue"
    t.index ["organization_id"], name: "index_supplier_activities_on_organization_id"
    t.index ["related_record_type", "related_record_id"], name: "index_supplier_activities_on_related_record"
    t.index ["related_user_id"], name: "index_supplier_activities_on_related_user_id"
    t.index ["supplier_contact_id"], name: "index_supplier_activities_on_supplier_contact_id"
    t.index ["supplier_id", "activity_date"], name: "index_supplier_activities_on_supplier_id_and_activity_date"
    t.index ["supplier_id", "activity_type"], name: "index_supplier_activities_on_supplier_id_and_activity_type"
    t.index ["supplier_id"], name: "index_supplier_activities_on_supplier_id"
  end

  create_table "supplier_addresses", force: :cascade do |t|
    t.string "access_code"
    t.string "address_label"
    t.string "address_type", null: false
    t.string "attention_to"
    t.text "certifications_at_location"
    t.string "city", null: false
    t.string "contact_email"
    t.string "contact_fax"
    t.string "contact_phone"
    t.string "country", default: "US", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.boolean "deleted", default: false
    t.string "dock_gate_info"
    t.text "equipment_available"
    t.integer "facility_size_sqft"
    t.boolean "is_active", default: true
    t.boolean "is_default", default: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "operating_hours"
    t.bigint "organization_id"
    t.string "postal_code", null: false
    t.string "receiving_hours"
    t.boolean "requires_appointment", default: false
    t.text "shipping_instructions"
    t.text "special_instructions"
    t.string "state_province"
    t.string "street_address_1", null: false
    t.string "street_address_2"
    t.bigint "supplier_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.integer "warehouse_capacity_pallets"
    t.index ["country"], name: "index_supplier_addresses_on_country"
    t.index ["created_by_id"], name: "index_supplier_addresses_on_created_by_id"
    t.index ["is_active"], name: "index_supplier_addresses_on_is_active"
    t.index ["organization_id"], name: "index_supplier_addresses_on_organization_id"
    t.index ["supplier_id", "address_type"], name: "index_supplier_addresses_on_supplier_id_and_address_type"
    t.index ["supplier_id", "is_default"], name: "index_supplier_addresses_on_supplier_id_and_is_default"
    t.index ["supplier_id"], name: "index_supplier_addresses_on_supplier_id"
    t.index ["updated_by_id"], name: "index_supplier_addresses_on_updated_by_id"
  end

  create_table "supplier_contacts", force: :cascade do |t|
    t.date "anniversary"
    t.date "birthday"
    t.text "communication_notes"
    t.integer "contact_frequency_days"
    t.string "contact_role", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.boolean "deleted", default: false
    t.string "department"
    t.string "direct_line"
    t.string "email", null: false
    t.string "extension"
    t.string "fax"
    t.string "first_name", null: false
    t.boolean "is_active", default: true
    t.boolean "is_after_hours_contact", default: false
    t.boolean "is_decision_maker", default: false
    t.boolean "is_escalation_contact", default: false
    t.boolean "is_primary_contact", default: false
    t.text "languages_spoken"
    t.datetime "last_contacted_at"
    t.bigint "last_contacted_by_id"
    t.string "last_name", null: false
    t.string "linkedin_url"
    t.string "mobile"
    t.bigint "organization_id"
    t.date "out_of_office_from"
    t.text "out_of_office_notes"
    t.date "out_of_office_to"
    t.text "personal_notes"
    t.string "phone", null: false
    t.string "preferred_contact_method"
    t.text "professional_notes"
    t.boolean "receive_general_updates", default: false
    t.boolean "receive_payment_confirmations", default: false
    t.boolean "receive_pos", default: true
    t.boolean "receive_quality_alerts", default: false
    t.boolean "receive_rfqs", default: true
    t.integer "relationship_strength", default: 1
    t.string "skype_id"
    t.bigint "supplier_id", null: false
    t.string "timezone"
    t.string "title"
    t.integer "total_interactions_count", default: 0
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.string "wechat_id"
    t.string "whatsapp_number"
    t.string "working_hours"
    t.index ["created_by_id"], name: "index_supplier_contacts_on_created_by_id"
    t.index ["email"], name: "index_supplier_contacts_on_email"
    t.index ["is_active"], name: "index_supplier_contacts_on_is_active"
    t.index ["is_decision_maker"], name: "index_supplier_contacts_on_is_decision_maker"
    t.index ["last_contacted_by_id"], name: "index_supplier_contacts_on_last_contacted_by_id"
    t.index ["organization_id"], name: "index_supplier_contacts_on_organization_id"
    t.index ["supplier_id", "contact_role"], name: "index_supplier_contacts_on_supplier_id_and_contact_role"
    t.index ["supplier_id", "is_primary_contact"], name: "index_supplier_contacts_on_supplier_id_and_is_primary_contact"
    t.index ["supplier_id"], name: "index_supplier_contacts_on_supplier_id"
    t.index ["updated_by_id"], name: "index_supplier_contacts_on_updated_by_id"
  end

  create_table "supplier_documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "description"
    t.string "document_category"
    t.string "document_number"
    t.string "document_title", null: false
    t.string "document_type", null: false
    t.date "effective_date"
    t.date "expiry_date"
    t.string "file"
    t.string "file_content_type"
    t.string "file_name"
    t.integer "file_size"
    t.boolean "is_active", default: true
    t.boolean "is_confidential", default: false
    t.text "issuing_authority"
    t.text "notes"
    t.bigint "organization_id"
    t.date "renewal_date"
    t.integer "renewal_reminder_days", default: 30
    t.boolean "requires_renewal", default: false
    t.bigint "superseded_by_id"
    t.boolean "supplier_can_view", default: false
    t.bigint "supplier_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_id"
    t.integer "version", default: 1
    t.index ["created_by_id"], name: "index_supplier_documents_on_created_by_id"
    t.index ["document_type"], name: "index_supplier_documents_on_document_type"
    t.index ["expiry_date"], name: "index_supplier_documents_on_expiry_date"
    t.index ["is_active"], name: "index_supplier_documents_on_is_active"
    t.index ["organization_id"], name: "index_supplier_documents_on_organization_id"
    t.index ["superseded_by_id"], name: "index_supplier_documents_on_superseded_by_id"
    t.index ["supplier_id", "document_type"], name: "index_supplier_documents_on_supplier_id_and_document_type"
    t.index ["supplier_id"], name: "index_supplier_documents_on_supplier_id"
    t.index ["uploaded_by_id"], name: "index_supplier_documents_on_uploaded_by_id"
  end

  create_table "supplier_performance_reviews", force: :cascade do |t|
    t.text "action_items"
    t.bigint "approved_by_id"
    t.date "approved_date"
    t.text "areas_for_improvement"
    t.decimal "average_delay_days", precision: 8, scale: 2
    t.decimal "average_order_value", precision: 15, scale: 2
    t.decimal "cost_score", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.integer "critical_issues_count"
    t.decimal "delivery_score", precision: 5, scale: 2
    t.text "future_concerns"
    t.text "future_opportunities"
    t.decimal "innovation_score", precision: 5, scale: 2
    t.text "internal_notes"
    t.integer "late_deliveries_count"
    t.date "next_review_date"
    t.integer "on_time_deliveries_count"
    t.decimal "on_time_delivery_rate", precision: 5, scale: 2
    t.decimal "order_fill_rate", precision: 5, scale: 2
    t.bigint "organization_id"
    t.decimal "overall_score", precision: 5, scale: 2
    t.string "performance_rating"
    t.date "period_end_date", null: false
    t.date "period_start_date", null: false
    t.integer "price_decreases_count"
    t.integer "price_increases_count"
    t.decimal "price_variance_percentage", precision: 5, scale: 2
    t.decimal "quality_acceptance_rate", precision: 5, scale: 2
    t.integer "quality_issues_count"
    t.decimal "quality_score", precision: 5, scale: 2
    t.integer "receipts_rejected_count"
    t.boolean "recommend_continuation", default: true
    t.boolean "recommend_expansion", default: false
    t.boolean "recommend_reduction", default: false
    t.boolean "recommend_termination", default: false
    t.text "recommendation_notes"
    t.text "relationship_status"
    t.decimal "responsiveness_score", precision: 5, scale: 2
    t.date "review_date", null: false
    t.string "review_period"
    t.string "review_status", default: "DRAFT"
    t.string "review_type", default: "QUARTERLY"
    t.bigint "reviewed_by_id"
    t.text "risk_assessment"
    t.decimal "service_score", precision: 5, scale: 2
    t.bigint "shared_by_id"
    t.date "shared_date"
    t.boolean "shared_with_supplier", default: false
    t.text "strategic_importance"
    t.text "strengths"
    t.text "supplier_comments"
    t.text "supplier_feedback"
    t.bigint "supplier_id", null: false
    t.integer "total_deliveries_count"
    t.integer "total_orders_count"
    t.integer "total_receipts_count"
    t.decimal "total_spend_amount", precision: 15, scale: 2
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_supplier_performance_reviews_on_approved_by_id"
    t.index ["created_by_id"], name: "index_supplier_performance_reviews_on_created_by_id"
    t.index ["organization_id"], name: "index_supplier_performance_reviews_on_organization_id"
    t.index ["overall_score"], name: "index_supplier_performance_reviews_on_overall_score"
    t.index ["period_start_date", "period_end_date"], name: "idx_on_period_start_date_period_end_date_3cca3f1623"
    t.index ["review_date"], name: "index_supplier_performance_reviews_on_review_date"
    t.index ["review_status"], name: "index_supplier_performance_reviews_on_review_status"
    t.index ["reviewed_by_id"], name: "index_supplier_performance_reviews_on_reviewed_by_id"
    t.index ["shared_by_id"], name: "index_supplier_performance_reviews_on_shared_by_id"
    t.index ["supplier_id", "review_date"], name: "idx_on_supplier_id_review_date_f5dbe68289"
    t.index ["supplier_id"], name: "index_supplier_performance_reviews_on_supplier_id"
  end

  create_table "supplier_quality_issues", force: :cascade do |t|
    t.bigint "assigned_to_id"
    t.text "attachments_description"
    t.date "audit_completed_date"
    t.date "audit_scheduled_date"
    t.date "closed_date"
    t.text "corrective_action_taken"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.decimal "credit_amount", precision: 15, scale: 2
    t.boolean "credit_issued", default: false
    t.date "credit_issued_date"
    t.boolean "credit_requested", default: false
    t.integer "days_to_resolve"
    t.date "detected_date"
    t.date "expected_resolution_date"
    t.decimal "financial_impact", precision: 15, scale: 2
    t.boolean "impacts_supplier_rating", default: true
    t.boolean "is_repeat_issue", default: false
    t.date "issue_date", null: false
    t.text "issue_description", null: false
    t.string "issue_number"
    t.string "issue_title", null: false
    t.string "issue_type"
    t.string "lot_batch_number"
    t.integer "occurrence_count", default: 1
    t.bigint "organization_id"
    t.text "preventive_action_taken"
    t.bigint "product_id"
    t.text "purchasing_team_notes"
    t.text "quality_team_notes"
    t.decimal "quantity_affected", precision: 15, scale: 2
    t.decimal "quantity_rejected", precision: 15, scale: 2
    t.decimal "quantity_returned", precision: 15, scale: 2
    t.decimal "quantity_reworked", precision: 15, scale: 2
    t.decimal "rating_impact_points", precision: 5, scale: 2
    t.bigint "related_issue_id"
    t.string "related_po_number"
    t.bigint "reported_by_id"
    t.boolean "requires_audit", default: false
    t.boolean "requires_corrective_action_verification", default: false
    t.date "resolution_date"
    t.text "root_cause_analysis"
    t.string "root_cause_category"
    t.string "severity", null: false
    t.string "status", default: "OPEN"
    t.boolean "supplier_acknowledged", default: false
    t.bigint "supplier_id", null: false
    t.boolean "supplier_notified"
    t.date "supplier_notified_date"
    t.text "supplier_response"
    t.date "supplier_response_date"
    t.integer "supplier_response_time_days"
    t.datetime "updated_at", null: false
    t.date "verification_completed_date"
    t.date "verification_due_date"
    t.index ["assigned_to_id"], name: "index_supplier_quality_issues_on_assigned_to_id"
    t.index ["created_by_id"], name: "index_supplier_quality_issues_on_created_by_id"
    t.index ["is_repeat_issue"], name: "index_supplier_quality_issues_on_is_repeat_issue"
    t.index ["issue_date"], name: "index_supplier_quality_issues_on_issue_date"
    t.index ["issue_number"], name: "index_supplier_quality_issues_on_issue_number", unique: true
    t.index ["organization_id"], name: "index_supplier_quality_issues_on_organization_id"
    t.index ["product_id", "status"], name: "index_supplier_quality_issues_on_product_id_and_status"
    t.index ["product_id"], name: "index_supplier_quality_issues_on_product_id"
    t.index ["related_issue_id"], name: "index_supplier_quality_issues_on_related_issue_id"
    t.index ["reported_by_id"], name: "index_supplier_quality_issues_on_reported_by_id"
    t.index ["severity"], name: "index_supplier_quality_issues_on_severity"
    t.index ["status"], name: "index_supplier_quality_issues_on_status"
    t.index ["supplier_id", "status"], name: "index_supplier_quality_issues_on_supplier_id_and_status"
    t.index ["supplier_id"], name: "index_supplier_quality_issues_on_supplier_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.decimal "actual_vs_promised_lead_time_ratio", precision: 5, scale: 2, default: "1.0"
    t.decimal "advance_payment_percentage", precision: 5, scale: 2
    t.bigint "approved_by_id"
    t.date "approved_date"
    t.decimal "average_delay_days", precision: 8, scale: 2, default: "0.0"
    t.decimal "average_po_value", precision: 15, scale: 2, default: "0.0"
    t.string "bank_account_number"
    t.string "bank_branch"
    t.string "bank_iban"
    t.string "bank_name"
    t.string "bank_routing_number"
    t.string "bank_swift_code"
    t.text "billing_address"
    t.string "business_registration_number"
    t.boolean "can_receive_pos", default: true
    t.boolean "can_receive_rfqs", default: true
    t.text "certifications"
    t.string "code"
    t.text "company_profile"
    t.datetime "created_at", null: false
    t.integer "created_by"
    t.bigint "created_by_id"
    t.decimal "credit_limit_extended", precision: 15, scale: 2, default: "0.0"
    t.string "currency", default: "USD"
    t.decimal "current_payable_balance", precision: 15, scale: 2, default: "0.0"
    t.bigint "default_buyer_id"
    t.integer "default_lead_time_days", default: 30
    t.string "default_payment_terms", default: "NET_30"
    t.boolean "deleted"
    t.datetime "deleted_at"
    t.bigint "deleted_by_id"
    t.decimal "delivery_score", precision: 5, scale: 2, default: "0.0"
    t.string "display_name"
    t.integer "early_payment_discount_days"
    t.decimal "early_payment_discount_percentage", precision: 5, scale: 2
    t.string "email"
    t.string "facebook_url"
    t.text "factory_locations"
    t.text "geographic_coverage"
    t.string "gst_number"
    t.text "internal_notes"
    t.boolean "is_1099_vendor", default: false
    t.boolean "is_active"
    t.boolean "is_deleted", default: false
    t.boolean "is_local_supplier", default: false
    t.boolean "is_minority_owned", default: false
    t.boolean "is_preferred_supplier", default: false
    t.boolean "is_strategic_supplier", default: false
    t.boolean "is_veteran_owned", default: false
    t.boolean "is_woman_owned", default: false
    t.boolean "iso_14001_certified", default: false
    t.date "iso_14001_expiry"
    t.boolean "iso_45001_certified", default: false
    t.date "iso_45001_expiry"
    t.boolean "iso_9001_certified", default: false
    t.date "iso_9001_expiry"
    t.date "last_audit_date"
    t.date "last_po_date"
    t.integer "late_deliveries_count", default: 0
    t.integer "lead_time_days"
    t.string "legal_name"
    t.string "linkedin_url"
    t.text "manufacturing_processes"
    t.text "materials_specialization"
    t.integer "maximum_order_quantity"
    t.integer "minimum_order_quantity", default: 1
    t.string "name"
    t.date "next_audit_due_date"
    t.decimal "on_time_delivery_rate", precision: 5, scale: 2, default: "100.0"
    t.decimal "order_frequency_days", precision: 8, scale: 2
    t.integer "order_multiple"
    t.bigint "organization_id"
    t.decimal "overall_rating", precision: 5, scale: 2, default: "0.0"
    t.string "payment_method"
    t.string "phone"
    t.integer "po_count_mtd", default: 0
    t.integer "po_count_ytd", default: 0
    t.decimal "price_score", precision: 5, scale: 2, default: "0.0"
    t.string "primary_email"
    t.string "primary_fax"
    t.string "primary_phone"
    t.integer "production_capacity_monthly"
    t.decimal "purchase_value_mtd", precision: 15, scale: 2, default: "0.0"
    t.decimal "purchase_value_ytd", precision: 15, scale: 2, default: "0.0"
    t.text "purchasing_notes"
    t.decimal "quality_acceptance_rate", precision: 5, scale: 2, default: "100.0"
    t.text "quality_control_capabilities"
    t.integer "quality_issues_count", default: 0
    t.decimal "quality_rejection_rate", precision: 5, scale: 2, default: "0.0"
    t.decimal "quality_score", precision: 5, scale: 2, default: "0.0"
    t.string "rating_label"
    t.date "rating_last_calculated_at"
    t.boolean "requires_advance_payment", default: false
    t.boolean "requires_tax_withholding", default: false
    t.text "risk_factors"
    t.integer "risk_level", default: 1
    t.decimal "service_score", precision: 5, scale: 2, default: "0.0"
    t.text "shipping_address"
    t.date "status_effective_date"
    t.string "status_reason"
    t.string "supplier_category"
    t.date "supplier_since"
    t.string "supplier_status", default: "PENDING"
    t.string "supplier_territory"
    t.string "supplier_type"
    t.string "tax_id"
    t.decimal "tax_withholding_percentage", precision: 5, scale: 2
    t.text "testing_capabilities"
    t.integer "total_po_count", default: 0
    t.decimal "total_purchase_value", precision: 15, scale: 2, default: "0.0"
    t.string "trade_name"
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.string "vat_number"
    t.string "website"
    t.index ["approved_by_id"], name: "index_suppliers_on_approved_by_id"
    t.index ["created_by_id"], name: "index_suppliers_on_created_by_id"
    t.index ["default_buyer_id"], name: "index_suppliers_on_default_buyer_id"
    t.index ["deleted_by_id"], name: "index_suppliers_on_deleted_by_id"
    t.index ["is_preferred_supplier"], name: "index_suppliers_on_is_preferred_supplier"
    t.index ["legal_name"], name: "index_suppliers_on_legal_name"
    t.index ["organization_id"], name: "index_suppliers_on_organization_id"
    t.index ["overall_rating"], name: "index_suppliers_on_overall_rating"
    t.index ["supplier_category"], name: "index_suppliers_on_supplier_category"
    t.index ["supplier_status"], name: "index_suppliers_on_supplier_status"
    t.index ["supplier_type"], name: "index_suppliers_on_supplier_type"
    t.index ["updated_by_id"], name: "index_suppliers_on_updated_by_id"
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
    t.bigint "organization_id"
    t.decimal "rate", precision: 6, scale: 4, default: "0.0"
    t.string "state_province"
    t.string "tax_authority_id"
    t.string "tax_type"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_tax_codes_on_code", unique: true
    t.index ["organization_id"], name: "index_tax_codes_on_organization_id"
  end

  create_table "unit_of_measures", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.boolean "is_decimal"
    t.string "name"
    t.bigint "organization_id"
    t.string "symbol"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_unit_of_measures_on_organization_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.boolean "deleted", default: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "full_name"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.bigint "organization_id"
    t.string "phone"
    t.string "phone_number"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0
    t.integer "sign_in_count"
    t.datetime "updated_at", null: false
    t.index ["organization_id", "email"], name: "index_users_on_organization_id_and_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vendor_quotes", force: :cascade do |t|
    t.text "alternate_description"
    t.text "alternate_notes"
    t.decimal "alternate_unit_price", precision: 15, scale: 4
    t.text "attachments_description"
    t.text "buyer_notes"
    t.boolean "can_meet_required_date", default: true
    t.boolean "certifications_included", default: false
    t.text "certifications_list"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "currency", default: "USD"
    t.integer "days_after_required_date"
    t.text "delivery_notes"
    t.decimal "delivery_rank", precision: 5, scale: 2
    t.decimal "delivery_score", precision: 5, scale: 2, default: "0.0"
    t.text "exclusions"
    t.boolean "is_alternate_offered", default: false
    t.boolean "is_best_value", default: false
    t.boolean "is_fastest_delivery", default: false
    t.boolean "is_latest_revision", default: true
    t.boolean "is_lowest_price", default: false
    t.boolean "is_recommended", default: false
    t.boolean "is_selected", default: false
    t.integer "lead_time_days", null: false
    t.boolean "meets_specifications", default: true
    t.integer "minimum_order_quantity"
    t.integer "order_multiple"
    t.bigint "organization_id"
    t.decimal "other_charges", precision: 15, scale: 2, default: "0.0"
    t.text "other_charges_description"
    t.integer "overall_rank"
    t.decimal "overall_score", precision: 5, scale: 2, default: "0.0"
    t.string "packaging_type"
    t.boolean "partial_delivery_offered", default: false
    t.string "payment_terms"
    t.text "payment_terms_details"
    t.decimal "price_break_1_price", precision: 15, scale: 4
    t.decimal "price_break_1_qty", precision: 15, scale: 2
    t.decimal "price_break_2_price", precision: 15, scale: 4
    t.decimal "price_break_2_qty", precision: 15, scale: 2
    t.decimal "price_break_3_price", precision: 15, scale: 4
    t.decimal "price_break_3_qty", precision: 15, scale: 2
    t.decimal "price_rank", precision: 5, scale: 2
    t.decimal "price_score", precision: 5, scale: 2, default: "0.0"
    t.decimal "price_vs_average_percentage", precision: 5, scale: 2
    t.decimal "price_vs_last_purchase_percentage", precision: 5, scale: 2
    t.decimal "price_vs_lowest_percentage", precision: 5, scale: 2
    t.decimal "price_vs_target_percentage", precision: 5, scale: 2
    t.date "promised_delivery_date"
    t.decimal "quality_score", precision: 5, scale: 2, default: "0.0"
    t.date "quote_date", null: false
    t.string "quote_number"
    t.integer "quote_revision", default: 1
    t.string "quote_status", default: "SUBMITTED"
    t.date "quote_valid_until"
    t.text "review_notes"
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.text "revision_notes"
    t.bigint "rfq_id", null: false
    t.bigint "rfq_item_id", null: false
    t.bigint "rfq_supplier_id", null: false
    t.decimal "sample_cost", precision: 15, scale: 2
    t.integer "sample_lead_time_days"
    t.boolean "samples_available", default: false
    t.bigint "selected_by_id"
    t.date "selected_date"
    t.text "selection_reason"
    t.decimal "service_score", precision: 5, scale: 2, default: "0.0"
    t.decimal "setup_cost", precision: 15, scale: 2, default: "0.0"
    t.decimal "shipping_cost", precision: 15, scale: 2, default: "0.0"
    t.text "special_conditions"
    t.text "specification_deviations"
    t.bigint "superseded_by_id"
    t.bigint "supplier_id", null: false
    t.text "supplier_notes"
    t.text "technical_notes"
    t.decimal "tooling_cost", precision: 15, scale: 2, default: "0.0"
    t.decimal "total_cost", precision: 15, scale: 2
    t.decimal "total_cost_rank", precision: 5, scale: 2
    t.decimal "total_price", precision: 15, scale: 2, null: false
    t.decimal "unit_price", precision: 15, scale: 4, null: false
    t.integer "units_per_package"
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.integer "validity_days"
    t.text "warranty_details"
    t.string "warranty_period"
    t.index ["created_by_id"], name: "index_vendor_quotes_on_created_by_id"
    t.index ["is_best_value"], name: "index_vendor_quotes_on_is_best_value"
    t.index ["is_fastest_delivery"], name: "index_vendor_quotes_on_is_fastest_delivery"
    t.index ["is_latest_revision"], name: "index_vendor_quotes_on_is_latest_revision"
    t.index ["is_lowest_price"], name: "index_vendor_quotes_on_is_lowest_price"
    t.index ["is_selected"], name: "index_vendor_quotes_on_is_selected"
    t.index ["organization_id"], name: "index_vendor_quotes_on_organization_id"
    t.index ["overall_rank"], name: "index_vendor_quotes_on_overall_rank"
    t.index ["quote_date"], name: "index_vendor_quotes_on_quote_date"
    t.index ["quote_status"], name: "index_vendor_quotes_on_quote_status"
    t.index ["quote_valid_until"], name: "index_vendor_quotes_on_quote_valid_until"
    t.index ["reviewed_by_id"], name: "index_vendor_quotes_on_reviewed_by_id"
    t.index ["rfq_id", "rfq_item_id", "supplier_id"], name: "index_vendor_quotes_on_rfq_id_and_rfq_item_id_and_supplier_id"
    t.index ["rfq_id"], name: "index_vendor_quotes_on_rfq_id"
    t.index ["rfq_item_id"], name: "index_vendor_quotes_on_rfq_item_id"
    t.index ["rfq_supplier_id"], name: "index_vendor_quotes_on_rfq_supplier_id"
    t.index ["selected_by_id"], name: "index_vendor_quotes_on_selected_by_id"
    t.index ["superseded_by_id"], name: "index_vendor_quotes_on_superseded_by_id"
    t.index ["supplier_id"], name: "index_vendor_quotes_on_supplier_id"
    t.index ["updated_by_id"], name: "index_vendor_quotes_on_updated_by_id"
  end

  create_table "warehouses", force: :cascade do |t|
    t.text "address"
    t.string "code"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.boolean "is_active"
    t.string "name"
    t.bigint "organization_id"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_warehouses_on_organization_id"
  end

  create_table "work_centers", force: :cascade do |t|
    t.decimal "capacity_per_hour", precision: 10, scale: 2, default: "0.0"
    t.string "code", limit: 20, null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.boolean "deleted", default: false
    t.text "description"
    t.integer "efficiency_percent", default: 100
    t.boolean "is_active", default: true
    t.decimal "labor_cost_per_hour", precision: 10, scale: 2, default: "0.0"
    t.bigint "location_id"
    t.string "name", limit: 100, null: false
    t.text "notes"
    t.bigint "organization_id"
    t.decimal "overhead_cost_per_hour", precision: 10, scale: 2, default: "0.0"
    t.integer "queue_time_minutes", default: 0
    t.integer "setup_time_minutes", default: 0
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id"
    t.string "work_center_type", limit: 30, null: false
    t.index ["code"], name: "index_work_centers_on_code", unique: true
    t.index ["created_by_id"], name: "index_work_centers_on_created_by_id"
    t.index ["is_active"], name: "index_work_centers_on_is_active"
    t.index ["location_id"], name: "index_work_centers_on_location_id"
    t.index ["organization_id"], name: "index_work_centers_on_organization_id"
    t.index ["warehouse_id", "is_active"], name: "index_work_centers_on_warehouse_id_and_is_active"
    t.index ["warehouse_id"], name: "index_work_centers_on_warehouse_id"
    t.index ["work_center_type"], name: "index_work_centers_on_work_center_type"
  end

  create_table "work_order_materials", force: :cascade do |t|
    t.datetime "allocated_at"
    t.bigint "batch_id"
    t.bigint "bom_item_id"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.datetime "issued_at"
    t.bigint "issued_by_id"
    t.bigint "location_id"
    t.text "notes"
    t.bigint "organization_id"
    t.bigint "product_id", null: false
    t.decimal "quantity_allocated", precision: 14, scale: 4, default: "0.0"
    t.decimal "quantity_consumed", precision: 14, scale: 4, default: "0.0"
    t.decimal "quantity_required", precision: 14, scale: 4, null: false
    t.string "status", limit: 20, default: "REQUIRED"
    t.decimal "total_cost", precision: 12, scale: 2, default: "0.0"
    t.decimal "unit_cost", precision: 12, scale: 4, default: "0.0"
    t.bigint "uom_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "work_order_id", null: false
    t.index ["batch_id"], name: "index_work_order_materials_on_batch_id"
    t.index ["bom_item_id"], name: "index_work_order_materials_on_bom_item_id"
    t.index ["deleted"], name: "index_work_order_materials_on_deleted"
    t.index ["issued_by_id"], name: "index_work_order_materials_on_issued_by_id"
    t.index ["location_id", "product_id"], name: "index_work_order_materials_on_location_id_and_product_id"
    t.index ["location_id"], name: "index_work_order_materials_on_location_id"
    t.index ["organization_id"], name: "index_work_order_materials_on_organization_id"
    t.index ["product_id"], name: "index_work_order_materials_on_product_id"
    t.index ["status"], name: "index_work_order_materials_on_status"
    t.index ["uom_id"], name: "index_work_order_materials_on_uom_id"
    t.index ["work_order_id", "product_id"], name: "index_work_order_materials_on_work_order_id_and_product_id"
    t.index ["work_order_id"], name: "index_work_order_materials_on_work_order_id"
  end

  create_table "work_order_operations", force: :cascade do |t|
    t.decimal "actual_cost", precision: 12, scale: 2, default: "0.0"
    t.integer "actual_run_minutes", default: 0
    t.integer "actual_setup_minutes", default: 0
    t.integer "actual_total_minutes", default: 0
    t.datetime "assigned_at"
    t.bigint "assigned_by_id"
    t.bigint "assigned_operator_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false
    t.text "notes"
    t.text "operation_description"
    t.string "operation_name", limit: 100, null: false
    t.bigint "operator_id"
    t.bigint "organization_id"
    t.decimal "planned_cost", precision: 12, scale: 2, default: "0.0"
    t.decimal "planned_run_minutes_per_unit", precision: 10, scale: 2, default: "0.0"
    t.integer "planned_setup_minutes", default: 0
    t.integer "planned_total_minutes", default: 0
    t.decimal "quantity_completed", precision: 14, scale: 4, default: "0.0"
    t.decimal "quantity_scrapped", precision: 14, scale: 4, default: "0.0"
    t.decimal "quantity_to_process", precision: 14, scale: 4, null: false
    t.bigint "routing_operation_id", null: false
    t.integer "sequence_no", null: false
    t.datetime "started_at"
    t.string "status", limit: 20, default: "PENDING", null: false
    t.datetime "updated_at", null: false
    t.bigint "work_center_id", null: false
    t.bigint "work_order_id", null: false
    t.index ["assigned_at"], name: "index_work_order_operations_on_assigned_at"
    t.index ["assigned_operator_id"], name: "index_work_order_operations_on_assigned_operator_id"
    t.index ["deleted"], name: "index_work_order_operations_on_deleted"
    t.index ["operator_id"], name: "index_work_order_operations_on_operator_id"
    t.index ["organization_id"], name: "index_work_order_operations_on_organization_id"
    t.index ["routing_operation_id"], name: "index_work_order_operations_on_routing_operation_id"
    t.index ["status"], name: "index_work_order_operations_on_status"
    t.index ["work_center_id", "status"], name: "index_work_order_operations_on_work_center_id_and_status"
    t.index ["work_center_id"], name: "index_work_order_operations_on_work_center_id"
    t.index ["work_order_id", "sequence_no"], name: "index_work_order_operations_on_work_order_id_and_sequence_no"
    t.index ["work_order_id"], name: "index_work_order_operations_on_work_order_id"
  end

  create_table "work_orders", force: :cascade do |t|
    t.datetime "actual_end_date"
    t.decimal "actual_labor_cost", precision: 12, scale: 2, default: "0.0"
    t.decimal "actual_material_cost", precision: 12, scale: 2, default: "0.0"
    t.decimal "actual_overhead_cost", precision: 12, scale: 2, default: "0.0"
    t.datetime "actual_start_date"
    t.bigint "bom_id"
    t.datetime "completed_at"
    t.bigint "completed_by_id"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.bigint "customer_id"
    t.boolean "deleted", default: false
    t.text "notes"
    t.bigint "organization_id"
    t.decimal "planned_labor_cost", precision: 12, scale: 2, default: "0.0"
    t.decimal "planned_material_cost", precision: 12, scale: 2, default: "0.0"
    t.decimal "planned_overhead_cost", precision: 12, scale: 2, default: "0.0"
    t.string "priority", limit: 10, default: "NORMAL"
    t.bigint "product_id", null: false
    t.decimal "quantity_completed", precision: 14, scale: 4, default: "0.0"
    t.decimal "quantity_scrapped", precision: 14, scale: 4, default: "0.0"
    t.decimal "quantity_to_produce", precision: 14, scale: 4, null: false
    t.datetime "released_at"
    t.bigint "released_by_id"
    t.bigint "routing_id"
    t.date "scheduled_end_date"
    t.date "scheduled_start_date"
    t.string "status", limit: 20, default: "NOT_STARTED", null: false
    t.bigint "uom_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id", null: false
    t.string "wo_number", limit: 50, null: false
    t.index ["bom_id"], name: "index_work_orders_on_bom_id"
    t.index ["completed_by_id"], name: "index_work_orders_on_completed_by_id"
    t.index ["created_by_id"], name: "index_work_orders_on_created_by_id"
    t.index ["customer_id"], name: "index_work_orders_on_customer_id"
    t.index ["deleted"], name: "index_work_orders_on_deleted"
    t.index ["organization_id"], name: "index_work_orders_on_organization_id"
    t.index ["priority"], name: "index_work_orders_on_priority"
    t.index ["product_id", "status"], name: "index_work_orders_on_product_id_and_status"
    t.index ["product_id"], name: "index_work_orders_on_product_id"
    t.index ["released_by_id"], name: "index_work_orders_on_released_by_id"
    t.index ["routing_id"], name: "index_work_orders_on_routing_id"
    t.index ["scheduled_end_date"], name: "index_work_orders_on_scheduled_end_date"
    t.index ["scheduled_start_date"], name: "index_work_orders_on_scheduled_start_date"
    t.index ["status"], name: "index_work_orders_on_status"
    t.index ["uom_id"], name: "index_work_orders_on_uom_id"
    t.index ["warehouse_id", "status"], name: "index_work_orders_on_warehouse_id_and_status"
    t.index ["warehouse_id"], name: "index_work_orders_on_warehouse_id"
    t.index ["wo_number"], name: "index_work_orders_on_wo_number", unique: true
  end

  add_foreign_key "accounts", "organizations"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bill_of_materials", "organizations"
  add_foreign_key "bill_of_materials", "products"
  add_foreign_key "bom_items", "bill_of_materials"
  add_foreign_key "bom_items", "organizations"
  add_foreign_key "bom_items", "products", column: "component_id"
  add_foreign_key "bom_items", "unit_of_measures", column: "uom_id"
  add_foreign_key "customer_activities", "customer_contacts"
  add_foreign_key "customer_activities", "customers"
  add_foreign_key "customer_activities", "organizations"
  add_foreign_key "customer_activities", "users", column: "created_by_id"
  add_foreign_key "customer_activities", "users", column: "related_user_id"
  add_foreign_key "customer_addresses", "customers"
  add_foreign_key "customer_addresses", "organizations"
  add_foreign_key "customer_addresses", "users", column: "created_by_id"
  add_foreign_key "customer_contacts", "customers"
  add_foreign_key "customer_contacts", "organizations"
  add_foreign_key "customer_contacts", "users", column: "created_by_id"
  add_foreign_key "customer_documents", "customer_documents", column: "superseded_by_id"
  add_foreign_key "customer_documents", "customers"
  add_foreign_key "customer_documents", "organizations"
  add_foreign_key "customer_documents", "users", column: "uploaded_by_id"
  add_foreign_key "customers", "organizations"
  add_foreign_key "customers", "users", column: "approved_by_id", on_delete: :nullify
  add_foreign_key "customers", "users", column: "last_modified_by_id", on_delete: :nullify
  add_foreign_key "cycle_count_lines", "cycle_counts"
  add_foreign_key "cycle_count_lines", "locations"
  add_foreign_key "cycle_count_lines", "products"
  add_foreign_key "cycle_count_lines", "stock_batches", column: "batch_id"
  add_foreign_key "cycle_count_lines", "unit_of_measures", column: "uom_id"
  add_foreign_key "cycle_counts", "organizations"
  add_foreign_key "cycle_counts", "users", column: "counted_by_id"
  add_foreign_key "cycle_counts", "users", column: "posted_by_id"
  add_foreign_key "cycle_counts", "users", column: "scheduled_by_id"
  add_foreign_key "cycle_counts", "warehouses"
  add_foreign_key "goods_receipt_lines", "goods_receipts"
  add_foreign_key "goods_receipt_lines", "locations"
  add_foreign_key "goods_receipt_lines", "organizations"
  add_foreign_key "goods_receipt_lines", "products"
  add_foreign_key "goods_receipt_lines", "stock_batches", column: "batch_id"
  add_foreign_key "goods_receipt_lines", "unit_of_measures", column: "uom_id"
  add_foreign_key "goods_receipts", "organizations"
  add_foreign_key "goods_receipts", "purchase_orders"
  add_foreign_key "goods_receipts", "suppliers"
  add_foreign_key "goods_receipts", "users", column: "created_by_id"
  add_foreign_key "goods_receipts", "users", column: "posted_by_id"
  add_foreign_key "goods_receipts", "warehouses"
  add_foreign_key "item_planning_parameters", "organizations"
  add_foreign_key "item_planning_parameters", "products"
  add_foreign_key "item_planning_parameters", "users", column: "mrp_planner_id"
  add_foreign_key "journal_entries", "organizations"
  add_foreign_key "labor_time_entries", "organizations"
  add_foreign_key "labor_time_entries", "users", column: "operator_id"
  add_foreign_key "labor_time_entries", "work_order_operations"
  add_foreign_key "locations", "organizations"
  add_foreign_key "locations", "warehouses"
  add_foreign_key "mrp_action_messages", "customers"
  add_foreign_key "mrp_action_messages", "mrp_action_messages", column: "parent_action_id"
  add_foreign_key "mrp_action_messages", "mrp_runs"
  add_foreign_key "mrp_action_messages", "organizations"
  add_foreign_key "mrp_action_messages", "planned_purchase_orders"
  add_foreign_key "mrp_action_messages", "planned_work_orders"
  add_foreign_key "mrp_action_messages", "products"
  add_foreign_key "mrp_action_messages", "purchase_orders"
  add_foreign_key "mrp_action_messages", "suppliers"
  add_foreign_key "mrp_action_messages", "users", column: "assigned_to_id"
  add_foreign_key "mrp_action_messages", "users", column: "executed_by_id"
  add_foreign_key "mrp_action_messages", "work_orders"
  add_foreign_key "mrp_configurations", "organizations"
  add_foreign_key "mrp_demands", "customers"
  add_foreign_key "mrp_demands", "mrp_runs"
  add_foreign_key "mrp_demands", "organizations"
  add_foreign_key "mrp_demands", "products"
  add_foreign_key "mrp_exceptions", "customers"
  add_foreign_key "mrp_exceptions", "mrp_exceptions", column: "related_exception_id"
  add_foreign_key "mrp_exceptions", "mrp_runs"
  add_foreign_key "mrp_exceptions", "organizations"
  add_foreign_key "mrp_exceptions", "planned_purchase_orders", column: "related_planned_po_id"
  add_foreign_key "mrp_exceptions", "planned_work_orders", column: "related_planned_wo_id"
  add_foreign_key "mrp_exceptions", "products"
  add_foreign_key "mrp_exceptions", "purchase_orders", column: "related_purchase_order_id"
  add_foreign_key "mrp_exceptions", "users", column: "assigned_to_id"
  add_foreign_key "mrp_exceptions", "users", column: "resolved_by_id"
  add_foreign_key "mrp_exceptions", "work_orders", column: "related_work_order_id"
  add_foreign_key "mrp_runs", "mrp_runs", column: "previous_run_id"
  add_foreign_key "mrp_runs", "organizations"
  add_foreign_key "mrp_runs", "users", column: "approved_by_id"
  add_foreign_key "mrp_runs", "users", column: "run_by_id"
  add_foreign_key "mrp_supplies", "locations"
  add_foreign_key "mrp_supplies", "mrp_runs"
  add_foreign_key "mrp_supplies", "organizations"
  add_foreign_key "mrp_supplies", "products"
  add_foreign_key "mrp_supplies", "suppliers"
  add_foreign_key "mrp_supplies", "warehouses"
  add_foreign_key "organization_settings", "organizations"
  add_foreign_key "planned_purchase_orders", "mrp_runs"
  add_foreign_key "planned_purchase_orders", "organizations"
  add_foreign_key "planned_purchase_orders", "products"
  add_foreign_key "planned_purchase_orders", "rfqs"
  add_foreign_key "planned_purchase_orders", "sales_forecasts"
  add_foreign_key "planned_purchase_orders", "sales_orders"
  add_foreign_key "planned_purchase_orders", "suppliers"
  add_foreign_key "planned_purchase_orders", "unit_of_measures", column: "uom_id"
  add_foreign_key "planned_purchase_orders", "users", column: "approved_by_id"
  add_foreign_key "planned_purchase_orders", "users", column: "buyer_assigned_id"
  add_foreign_key "planned_purchase_orders", "users", column: "created_by_id"
  add_foreign_key "planned_purchase_orders", "users", column: "reviewed_by_id"
  add_foreign_key "planned_purchase_orders", "work_orders"
  add_foreign_key "planned_work_orders", "bill_of_materials", column: "bom_id"
  add_foreign_key "planned_work_orders", "customers"
  add_foreign_key "planned_work_orders", "mrp_runs"
  add_foreign_key "planned_work_orders", "organizations"
  add_foreign_key "planned_work_orders", "planned_work_orders", column: "parent_planned_wo_id"
  add_foreign_key "planned_work_orders", "products"
  add_foreign_key "planned_work_orders", "routings"
  add_foreign_key "planned_work_orders", "sales_forecasts"
  add_foreign_key "planned_work_orders", "sales_orders"
  add_foreign_key "planned_work_orders", "unit_of_measures", column: "uom_id"
  add_foreign_key "planned_work_orders", "users", column: "approved_by_id"
  add_foreign_key "planned_work_orders", "users", column: "created_by_id"
  add_foreign_key "planned_work_orders", "users", column: "production_planner_id"
  add_foreign_key "planned_work_orders", "users", column: "reviewed_by_id"
  add_foreign_key "planned_work_orders", "work_centers", column: "primary_work_center_id"
  add_foreign_key "planned_work_orders", "work_orders"
  add_foreign_key "planned_work_orders", "work_orders", column: "parent_work_order_id"
  add_foreign_key "product_categories", "organizations"
  add_foreign_key "product_suppliers", "organizations"
  add_foreign_key "product_suppliers", "products"
  add_foreign_key "product_suppliers", "suppliers"
  add_foreign_key "product_suppliers", "users", column: "created_by_id"
  add_foreign_key "product_suppliers", "users", column: "updated_by_id"
  add_foreign_key "products", "organizations"
  add_foreign_key "purchase_order_lines", "organizations"
  add_foreign_key "purchase_order_lines", "products"
  add_foreign_key "purchase_order_lines", "purchase_orders"
  add_foreign_key "purchase_order_lines", "rfq_items"
  add_foreign_key "purchase_order_lines", "tax_codes"
  add_foreign_key "purchase_order_lines", "unit_of_measures", column: "uom_id"
  add_foreign_key "purchase_order_lines", "vendor_quotes"
  add_foreign_key "purchase_orders", "organizations"
  add_foreign_key "purchase_orders", "rfqs"
  add_foreign_key "purchase_orders", "suppliers"
  add_foreign_key "purchase_orders", "users", column: "closed_by_id"
  add_foreign_key "purchase_orders", "users", column: "confirmed_by_id"
  add_foreign_key "purchase_orders", "users", column: "created_by_id"
  add_foreign_key "purchase_orders", "warehouses"
  add_foreign_key "rfq_items", "organizations"
  add_foreign_key "rfq_items", "products"
  add_foreign_key "rfq_items", "rfqs"
  add_foreign_key "rfq_items", "suppliers", column: "last_purchased_from_id"
  add_foreign_key "rfq_items", "suppliers", column: "selected_supplier_id"
  add_foreign_key "rfq_items", "users", column: "created_by_id"
  add_foreign_key "rfq_items", "users", column: "updated_by_id"
  add_foreign_key "rfq_suppliers", "organizations"
  add_foreign_key "rfq_suppliers", "rfqs"
  add_foreign_key "rfq_suppliers", "supplier_contacts"
  add_foreign_key "rfq_suppliers", "suppliers"
  add_foreign_key "rfq_suppliers", "users", column: "invited_by_id"
  add_foreign_key "rfqs", "organizations"
  add_foreign_key "rfqs", "suppliers", column: "awarded_supplier_id"
  add_foreign_key "rfqs", "suppliers", column: "recommended_supplier_id"
  add_foreign_key "rfqs", "users", column: "approver_id"
  add_foreign_key "rfqs", "users", column: "buyer_assigned_id"
  add_foreign_key "rfqs", "users", column: "created_by_id"
  add_foreign_key "rfqs", "users", column: "deleted_by_id"
  add_foreign_key "rfqs", "users", column: "requester_id"
  add_foreign_key "rfqs", "users", column: "updated_by_id"
  add_foreign_key "routing_operations", "organizations"
  add_foreign_key "routing_operations", "routings"
  add_foreign_key "routing_operations", "work_centers"
  add_foreign_key "routings", "organizations"
  add_foreign_key "routings", "products"
  add_foreign_key "routings", "users", column: "created_by_id"
  add_foreign_key "sales_forecasts", "customers"
  add_foreign_key "sales_forecasts", "organizations"
  add_foreign_key "sales_forecasts", "products"
  add_foreign_key "sales_forecasts", "sales_forecasts", column: "superseded_by_id"
  add_foreign_key "sales_forecasts", "users", column: "approved_by_id"
  add_foreign_key "sales_forecasts", "users", column: "created_by_id"
  add_foreign_key "stock_adjustment_lines", "locations"
  add_foreign_key "stock_adjustment_lines", "organizations"
  add_foreign_key "stock_adjustment_lines", "products"
  add_foreign_key "stock_adjustment_lines", "stock_adjustments"
  add_foreign_key "stock_adjustment_lines", "stock_batches", column: "batch_id"
  add_foreign_key "stock_adjustment_lines", "unit_of_measures", column: "uom_id"
  add_foreign_key "stock_adjustments", "organizations"
  add_foreign_key "stock_adjustments", "users", column: "approved_by_id"
  add_foreign_key "stock_adjustments", "users", column: "created_by_id"
  add_foreign_key "stock_adjustments", "users", column: "posted_by_id"
  add_foreign_key "stock_adjustments", "warehouses"
  add_foreign_key "stock_batches", "organizations"
  add_foreign_key "stock_batches", "products"
  add_foreign_key "stock_batches", "users", column: "created_by_id"
  add_foreign_key "stock_issue_lines", "organizations"
  add_foreign_key "stock_issue_lines", "products"
  add_foreign_key "stock_issue_lines", "stock_batches"
  add_foreign_key "stock_issue_lines", "stock_issues"
  add_foreign_key "stock_issues", "organizations"
  add_foreign_key "stock_issues", "warehouses"
  add_foreign_key "stock_levels", "locations"
  add_foreign_key "stock_levels", "organizations"
  add_foreign_key "stock_levels", "products"
  add_foreign_key "stock_levels", "stock_batches", column: "batch_id"
  add_foreign_key "stock_transactions", "locations", column: "from_location_id"
  add_foreign_key "stock_transactions", "locations", column: "to_location_id"
  add_foreign_key "stock_transactions", "organizations"
  add_foreign_key "stock_transactions", "products"
  add_foreign_key "stock_transactions", "stock_batches", column: "batch_id"
  add_foreign_key "stock_transactions", "unit_of_measures", column: "uom_id"
  add_foreign_key "stock_transactions", "users", column: "created_by_id"
  add_foreign_key "stock_transfer_lines", "locations", column: "from_location_id"
  add_foreign_key "stock_transfer_lines", "locations", column: "to_location_id"
  add_foreign_key "stock_transfer_lines", "organizations"
  add_foreign_key "stock_transfer_lines", "products"
  add_foreign_key "stock_transfer_lines", "stock_batches", column: "batch_id"
  add_foreign_key "stock_transfer_lines", "stock_transfers"
  add_foreign_key "stock_transfer_lines", "unit_of_measures", column: "uom_id"
  add_foreign_key "stock_transfers", "organizations"
  add_foreign_key "stock_transfers", "users", column: "approved_by_id"
  add_foreign_key "stock_transfers", "users", column: "created_by_id"
  add_foreign_key "stock_transfers", "users", column: "requested_by_id"
  add_foreign_key "stock_transfers", "warehouses", column: "from_warehouse_id"
  add_foreign_key "stock_transfers", "warehouses", column: "to_warehouse_id"
  add_foreign_key "supplier_activities", "organizations"
  add_foreign_key "supplier_activities", "supplier_contacts"
  add_foreign_key "supplier_activities", "suppliers"
  add_foreign_key "supplier_activities", "users", column: "created_by_id"
  add_foreign_key "supplier_activities", "users", column: "related_user_id"
  add_foreign_key "supplier_addresses", "organizations"
  add_foreign_key "supplier_addresses", "suppliers"
  add_foreign_key "supplier_addresses", "users", column: "created_by_id"
  add_foreign_key "supplier_addresses", "users", column: "updated_by_id"
  add_foreign_key "supplier_contacts", "organizations"
  add_foreign_key "supplier_contacts", "suppliers"
  add_foreign_key "supplier_contacts", "users", column: "created_by_id"
  add_foreign_key "supplier_contacts", "users", column: "last_contacted_by_id"
  add_foreign_key "supplier_contacts", "users", column: "updated_by_id"
  add_foreign_key "supplier_documents", "organizations"
  add_foreign_key "supplier_documents", "supplier_documents", column: "superseded_by_id"
  add_foreign_key "supplier_documents", "suppliers"
  add_foreign_key "supplier_documents", "users", column: "created_by_id"
  add_foreign_key "supplier_documents", "users", column: "uploaded_by_id"
  add_foreign_key "supplier_performance_reviews", "organizations"
  add_foreign_key "supplier_performance_reviews", "suppliers"
  add_foreign_key "supplier_performance_reviews", "users", column: "approved_by_id"
  add_foreign_key "supplier_performance_reviews", "users", column: "created_by_id"
  add_foreign_key "supplier_performance_reviews", "users", column: "reviewed_by_id"
  add_foreign_key "supplier_performance_reviews", "users", column: "shared_by_id"
  add_foreign_key "supplier_quality_issues", "organizations"
  add_foreign_key "supplier_quality_issues", "products"
  add_foreign_key "supplier_quality_issues", "supplier_quality_issues", column: "related_issue_id"
  add_foreign_key "supplier_quality_issues", "suppliers"
  add_foreign_key "supplier_quality_issues", "users", column: "assigned_to_id"
  add_foreign_key "supplier_quality_issues", "users", column: "created_by_id"
  add_foreign_key "supplier_quality_issues", "users", column: "reported_by_id"
  add_foreign_key "suppliers", "organizations"
  add_foreign_key "suppliers", "users", column: "approved_by_id"
  add_foreign_key "suppliers", "users", column: "created_by_id"
  add_foreign_key "suppliers", "users", column: "default_buyer_id"
  add_foreign_key "suppliers", "users", column: "deleted_by_id"
  add_foreign_key "suppliers", "users", column: "updated_by_id"
  add_foreign_key "tax_codes", "organizations"
  add_foreign_key "unit_of_measures", "organizations"
  add_foreign_key "users", "organizations"
  add_foreign_key "vendor_quotes", "organizations"
  add_foreign_key "vendor_quotes", "rfq_items"
  add_foreign_key "vendor_quotes", "rfq_suppliers"
  add_foreign_key "vendor_quotes", "rfqs"
  add_foreign_key "vendor_quotes", "suppliers"
  add_foreign_key "vendor_quotes", "users", column: "created_by_id"
  add_foreign_key "vendor_quotes", "users", column: "reviewed_by_id"
  add_foreign_key "vendor_quotes", "users", column: "selected_by_id"
  add_foreign_key "vendor_quotes", "users", column: "updated_by_id"
  add_foreign_key "vendor_quotes", "vendor_quotes", column: "superseded_by_id"
  add_foreign_key "warehouses", "organizations"
  add_foreign_key "work_centers", "locations"
  add_foreign_key "work_centers", "organizations"
  add_foreign_key "work_centers", "users", column: "created_by_id"
  add_foreign_key "work_centers", "warehouses"
  add_foreign_key "work_order_materials", "bom_items"
  add_foreign_key "work_order_materials", "locations"
  add_foreign_key "work_order_materials", "organizations"
  add_foreign_key "work_order_materials", "products"
  add_foreign_key "work_order_materials", "stock_batches", column: "batch_id"
  add_foreign_key "work_order_materials", "unit_of_measures", column: "uom_id"
  add_foreign_key "work_order_materials", "users", column: "issued_by_id"
  add_foreign_key "work_order_materials", "work_orders"
  add_foreign_key "work_order_operations", "organizations"
  add_foreign_key "work_order_operations", "routing_operations"
  add_foreign_key "work_order_operations", "users", column: "operator_id"
  add_foreign_key "work_order_operations", "work_centers"
  add_foreign_key "work_order_operations", "work_orders"
  add_foreign_key "work_orders", "bill_of_materials", column: "bom_id"
  add_foreign_key "work_orders", "customers"
  add_foreign_key "work_orders", "organizations"
  add_foreign_key "work_orders", "products"
  add_foreign_key "work_orders", "routings"
  add_foreign_key "work_orders", "unit_of_measures", column: "uom_id"
  add_foreign_key "work_orders", "users", column: "completed_by_id"
  add_foreign_key "work_orders", "users", column: "created_by_id"
  add_foreign_key "work_orders", "users", column: "released_by_id"
  add_foreign_key "work_orders", "warehouses"
end
