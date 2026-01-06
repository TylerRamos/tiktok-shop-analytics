class TikTokShopProductSnapshot < ApplicationRecord
  belongs_to :tik_tok_shop_product

  validates :snapshot_date, presence: true, uniqueness: { scope: :tik_tok_shop_product_id }
end