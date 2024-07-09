# app/services/brave_search_service.rb
require 'httparty'

class BraveSearchService
  include HTTParty
  base_uri 'https://api.search.brave.com/res/v1/web'

  def initialize
    @api_key = ENV['BRAVE_API_KEY']
  end

  def search(query, options = {})
    headers = {
      "Accept" => "application/json",
      "User-Agent" => "Mozilla/5.0",
      "X-Subscription-Token" => @api_key
    }

    options = options.transform_values(&:presence).compact

    options = {
      q: query,
      country: options[:country] || 'us',
      search_lang: options[:search_lang] || 'en',
      ui_lang: options[:ui_lang] || 'en-US',
      count: options[:count] || 20,
      offset: options[:offset] || 0,
      safesearch: options[:safesearch] || 'moderate'
    }.compact

    Rails.logger.info("BraveSearchService Request URL: #{self.class.base_uri}")
    Rails.logger.info("BraveSearchService Request Headers: #{headers}")
    Rails.logger.info("BraveSearchService Request Options: #{options}")

    response = self.class.get('', query: options, headers: headers)
    Rails.logger.info("BraveSearchService Response Code: #{response.code}")
    Rails.logger.info("BraveSearchService Response Body: #{response.body}")

    JSON.parse(response.body)
  end
end
