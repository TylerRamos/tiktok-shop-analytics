class CreateTikTokShopProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :tik_tok_shop_products do |t|
      t.bigint :tik_tok_shop_id, null: false
      t.string :external_id, null: false
      t.string :title
      t.string :image_url
      t.integer :status
      t.integer :stock

      t.timestamps

      t.index [:tik_tok_shop_id, :external_id], unique: true, name: 'index_products_on_shop_and_external_id'
    end
  end
end