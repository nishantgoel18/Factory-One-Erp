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

ActiveRecord::Schema[8.1].define(version: 2025_11_23_171106) do
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

  create_table "unit_of_measures", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_decimal"
    t.string "name"
    t.string "symbol"
    t.datetime "updated_at", null: false
  end
end
