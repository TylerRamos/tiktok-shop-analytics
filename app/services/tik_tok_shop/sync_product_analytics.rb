module TikTokShop
  class SyncProductAnalytics
    def self.call(tik_tok_shop_id:, start_date:, end_date:, cookie:, oec_seller_id:, fp:)
      new(tik_tok_shop_id, start_date, end_date, cookie, oec_seller_id, fp).call
    end

    def initialize(tik_tok_shop_id, start_date, end_date, cookie, oec_seller_id, fp)
      @tik_tok_shop_id = tik_tok_shop_id
      @start_date = Date.parse(start_date.to_s)
      @end_date = Date.parse(end_date.to_s)
      @cookie = cookie
      @oec_seller_id = oec_seller_id
      @fp = fp
    end

    def call
      total_synced = 0
      Rails.logger.info "[TikTok Sync] Starting sync for shop #{@tik_tok_shop_id} from #{@start_date} to #{@end_date}"
      
      (@start_date..@end_date).each do |date|
        synced_count = sync_day(date)
        total_synced += synced_count
      end
      
      Rails.logger.info "[TikTok Sync] Completed sync for shop #{@tik_tok_shop_id}. Total items: #{total_synced}"
      { success: true, items_synced: total_synced }
    end

    private

    def sync_day(date)
      page = 0
      items_count = 0
      base_url = ENV.fetch('TIKTOK_BASE_URL', 'https://seller-us.tiktok.com')
      timezone_offset = ENV.fetch('TIKTOK_TIMEZONE_OFFSET', -28800).to_i
      
      loop do
        response = SignParamsService.get_products(
          cookie: @cookie,
          oec_seller_id: @oec_seller_id,
          base_url: base_url,
          fp: @fp,
          timezone_offset: timezone_offset,
          start_date: date.to_s,
          end_date: (date + 1).to_s,
          page: page,
          page_size: 50
        )

        unless response["code"] == 0
          Rails.logger.warn "[TikTok Sync] API returned code #{response["code"]} for #{date} (page #{page}): #{response["status_msg"]}"
          break
        end
        
        unless response["data"]["items"]&.any?
          Rails.logger.info "[TikTok Sync] No items found for #{date}" if page == 0
          break
        end

        response["data"]["items"].each do |item|
          upsert_product_and_snapshot(item, date)
          items_count += 1
        end

        has_more = response.dig("data", "list_control", "next_pagination", "has_more")
        Rails.logger.debug "[TikTok Sync] Synced page #{page} for #{date}: #{response["data"]["items"].length} items"
        
        break unless has_more
        page += 1
      end
      
      Rails.logger.info "[TikTok Sync] Completed #{date}: #{items_count} items synced across #{page + 1} page(s)"
      items_count
    rescue => e
      Rails.logger.error "[TikTok Sync] Failed to sync #{date}: #{e.class} - #{e.message}"
      raise
    end

    def upsert_product_and_snapshot(item, date)
      product = TikTokShopProduct.find_or_initialize_by(
        tik_tok_shop_id: @tik_tok_shop_id,
        external_id: item["meta"]["product_id"]
      )

      product.assign_attributes(
        title: item["meta"]["product_name"],
        image_url: item["meta"]["product_image"],
        status: item["meta"]["product_status"],
        stock: item["meta"]["inventory_cnt"]
      )
      product.save!

      TikTokShopProductSnapshot.find_or_initialize_by(
        tik_tok_shop_product_id: product.id,
        snapshot_date: date
      ).update!(
        tik_tok_shop_id: @tik_tok_shop_id,
        gmv: item["stats"]["gmv"]["amount"],
        items_sold: item["stats"]["unit_sold_cnt"],
        orders_count: item["stats"]["order_cnt"]
      )
    end
  end
end