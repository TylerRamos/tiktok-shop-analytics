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

ActiveRecord::Schema[8.1].define(version: 2026_01_06_024554) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "tik_tok_shop_product_snapshots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "gmv", precision: 10, scale: 2
    t.integer "items_sold"
    t.integer "orders_count"
    t.date "snapshot_date", null: false
    t.bigint "tik_tok_shop_id", null: false
    t.bigint "tik_tok_shop_product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["snapshot_date"], name: "index_tik_tok_shop_product_snapshots_on_snapshot_date"
    t.index ["tik_tok_shop_id"], name: "index_tik_tok_shop_product_snapshots_on_tik_tok_shop_id"
    t.index ["tik_tok_shop_product_id", "snapshot_date"], name: "index_snapshots_on_product_and_date", unique: true
  end

  create_table "tik_tok_shop_products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.string "image_url"
    t.integer "status"
    t.integer "stock"
    t.bigint "tik_tok_shop_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["tik_tok_shop_id", "external_id"], name: "index_products_on_shop_and_external_id", unique: true
  end
end
