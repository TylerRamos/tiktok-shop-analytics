module TikTokShop
  class ProductAnalyticsQuery
    def self.call(tik_tok_shop_id:, start_date:, end_date:, min_gmv_cents: nil)
      new(tik_tok_shop_id, start_date, end_date, min_gmv_cents).call
    end

    def initialize(tik_tok_shop_id, start_date, end_date, min_gmv_cents)
      @tik_tok_shop_id = tik_tok_shop_id
      @start_date = Date.parse(start_date.to_s)
      @end_date = Date.parse(end_date.to_s)
      @min_gmv_cents = min_gmv_cents
    end

    def call
      query = TikTokShopProduct
        .select(
          'tik_tok_shop_products.*',
          'SUM(tik_tok_shop_product_snapshots.gmv) as total_gmv',
          'SUM(tik_tok_shop_product_snapshots.items_sold) as total_items_sold',
          'SUM(tik_tok_shop_product_snapshots.orders_count) as total_orders_count'
        )
        .joins(:tik_tok_shop_product_snapshots)
        .where(tik_tok_shop_id: @tik_tok_shop_id)
        .where(
          tik_tok_shop_product_snapshots: { 
            snapshot_date: @start_date..@end_date 
          }
        )
        .group('tik_tok_shop_products.id')

      if @min_gmv_cents
        query = query.having('SUM(tik_tok_shop_product_snapshots.gmv) >= ?', @min_gmv_cents / 100.0)
      end

      query.map do |product|
        {
          external_id: product.external_id,
          title: product.title,
          status: product.status,
          image_url: product.image_url,
          gmv: product.total_gmv.to_f,
          items_sold: product.total_items_sold.to_i,
          orders_count: product.total_orders_count.to_i
        }
      end
    end
  end
end