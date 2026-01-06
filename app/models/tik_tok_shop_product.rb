class TikTokShopProduct < ApplicationRecord
  has_many :tik_tok_shop_product_snapshots, dependent: :destroy

  validates :external_id, presence: true, uniqueness: { scope: :tik_tok_shop_id }
end