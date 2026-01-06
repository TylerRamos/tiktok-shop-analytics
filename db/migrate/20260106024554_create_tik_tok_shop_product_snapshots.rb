class CreateTikTokShopProductSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :tik_tok_shop_product_snapshots do |t|
      t.bigint :tik_tok_shop_id, null: false
      t.bigint :tik_tok_shop_product_id, null: false
      t.date :snapshot_date, null: false
      t.decimal :gmv, precision: 10, scale: 2
      t.integer :items_sold
      t.integer :orders_count

      t.timestamps

      t.index [:tik_tok_shop_product_id, :snapshot_date], unique: true, name: 'index_snapshots_on_product_and_date'
      t.index :tik_tok_shop_id
      t.index :snapshot_date
    end
  end
end