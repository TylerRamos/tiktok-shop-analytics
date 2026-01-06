class SyncProductAnalyticsJob < ApplicationJob
  queue_as :default

  discard_on ArgumentError
  discard_on ActiveRecord::RecordInvalid
  
  # Retry with explicit exponential backoff: 3s, 18s, 83s
  retry_on StandardError, wait: :exponentially_longer, attempts: 3 do |job, error|
    Rails.logger.error "Final failure for TikTok Shop #{job.arguments.first[:tik_tok_shop_id]} after #{job.executions} attempts: #{error.message}"
    # external logging
  end

  def perform(tik_tok_shop_id:, start_date:, end_date:, cookie:, oec_seller_id:, fp:)
    validate_inputs!(tik_tok_shop_id, start_date, end_date)
    
    Rails.logger.info "Starting sync for TikTok Shop #{tik_tok_shop_id} from #{start_date} to #{end_date}"
    
    TikTokShop::SyncProductAnalytics.call(
      tik_tok_shop_id: tik_tok_shop_id,
      start_date: start_date,
      end_date: end_date,
      cookie: cookie,
      oec_seller_id: oec_seller_id,
      fp: fp
    )
    
    Rails.logger.info "Successfully synced TikTok Shop #{tik_tok_shop_id}"
  rescue => e
    Rails.logger.error "Failed to sync TikTok Shop #{tik_tok_shop_id}: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    raise # retry
  end

  private

  def validate_inputs!(shop_id, start_date, end_date)
    raise ArgumentError, "Invalid shop_id" unless shop_id.present?
    
    start_d = Date.parse(start_date.to_s)
    end_d = Date.parse(end_date.to_s)
    
    raise ArgumentError, "start_date cannot be in the future" if start_d > Date.today
    raise ArgumentError, "end_date cannot be before start_date" if end_d < start_d
  rescue Date::Error => e
    raise ArgumentError, "Invalid date format: #{e.message}"
  end
end