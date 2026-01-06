module Api
  module V1
    class TikTokShopsController < ApplicationController
      skip_before_action :verify_authenticity_token

      def product_analytics
        if params[:start_date].blank? || params[:end_date].blank?
          return render json: { error: 'start_date and end_date are required' }, status: :bad_request
        end

        begin
          start_date = Date.parse(params[:start_date])
          end_date = Date.parse(params[:end_date])
        rescue ArgumentError, TypeError
          return render json: { error: 'Invalid date format. Use YYYY-MM-DD' }, status: :bad_request
        end

        if end_date < start_date
          return render json: { error: 'end_date must be after start_date' }, status: :bad_request
        end

        min_gmv_cents = params[:min_gmv] ? (params[:min_gmv].to_f * 100).to_i : nil

        data = TikTokShop::ProductAnalyticsQuery.call(
          tik_tok_shop_id: params[:id],
          start_date: start_date,
          end_date: end_date,
          min_gmv_cents: min_gmv_cents
        )

        render json: { data: data }
      rescue => e
        Rails.logger.error "Product analytics query failed: #{e.message}"
        render json: { error: 'Internal server error' }, status: :internal_server_error
      end
    end
  end
end