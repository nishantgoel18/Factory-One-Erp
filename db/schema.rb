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

ActiveRecord::Schema[8.1].define(version: 2025_11_23_211423) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "product_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.string "name"
    t.integer "parent_id"
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_product_categories_on_parent_id"
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.boolean "is_active"
    t.boolean "is_batch_tracked"
    t.boolean "is_serial_tracked"
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

  create_table "unit_of_measures", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_decimal"
    t.string "name"
    t.string "symbol"
    t.datetime "updated_at", null: false
  end

  create_table "warehouses", force: :cascade do |t|
    t.text "address"
    t.string "code"
    t.datetime "created_at", null: false
    t.boolean "deleted"
    t.boolean "is_active"
    t.string "name"
    t.datetime "updated_at", null: false
  end
end
