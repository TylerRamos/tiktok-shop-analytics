require 'open3'
require 'json'

class SignParamsService
  GET_PRODUCTS_RUNNER = Rails.root.join('app/javascript/products.mjs')

  def self.get_products(
    cookie:,
    oec_seller_id:,
    base_url:,
    fp:,
    timezone_offset:,
    start_date:,
    end_date:,
    page: 0,
    page_size: 50
  )
    input_data = {
      cookie: cookie,
      oecSellerId: oec_seller_id,
      baseUrl: base_url,
      fp: fp,
      timezoneOffset: timezone_offset,
      startDate: start_date,
      endDate: end_date,
      page: page,
      pageSize: page_size
    }.compact.to_json

    stdout, stderr, status = Open3.capture3(
      'node',
      GET_PRODUCTS_RUNNER.to_s,
      stdin_data: input_data
    )

    unless status.success?
      Rails.logger.error("Node request failed: #{stderr}")
      raise "Request failed: #{stderr}"
    end

    JSON.parse(stdout.strip)
  end
end
