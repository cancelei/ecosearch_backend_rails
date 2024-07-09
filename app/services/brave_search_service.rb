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

    # Ensure that options hash includes all necessary keys with defaults if they are not provided
    params = {
      q: query,
      key: @api_key,
      country: options[:country] || 'us',
      search_lang: options[:search_lang] || 'en',
      ui_lang: options[:ui_lang] || 'en-US',
      count: options[:count] || 20,
      offset: options[:offset] || 0,
      safesearch: options[:safesearch] || 'moderate'
    }

    response = self.class.get('', query: params, headers: headers)
    response.parsed_response
  end
end
