# app/services/bing_search_service.rb
require 'httparty'

class BingSearchService
  include HTTParty
  base_uri 'https://api.bing.microsoft.com/v7.0'

  def initialize
    @api_key = ENV['BING_API_KEY']
  end

  def search(query:, count: 10, mkt: 'en-US', safesearch: 'Moderate', freshness: '', sortby: 'Relevance')
    options = {
      headers: { "Ocp-Apim-Subscription-Key" => @api_key },
      query: {
        q: query,
        count: count,
        mkt: mkt,
        safesearch: safesearch,
        freshness: freshness,
        sortby: sortby
      }
    }
    self.class.get('/search', options)
  end
end
