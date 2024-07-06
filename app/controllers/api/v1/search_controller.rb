# app/controllers/api/v1/search_controller.rb
require_relative '../../services/google_search_service'
require_relative '../../services/bing_search_service'
require_relative '../../services/brave_search_service'

module Api
  module V1
    class SearchController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [:search]
      # skip_before_action :authenticate_user!, only: [:search, :index]

      def index
        if params[:job_id].present?
          handle_get_request
        else
          render json: { error: 'job_id parameter is required, use search/search for POST than GET requests' }, status: :bad_request
        end
      end

      def search
        if request.get?
          handle_get_request
        else
          handle_post_request
        end
      end

      private

      def handle_post_request
        if params[:query].present? && params[:search_engine].present?
          job_id = initiate_search_job(params[:search_engine], params[:query], params[:count], params[:safesearch])
          if job_id
            render json: { job_id: job_id }, status: :accepted
          else
            render json: { error: 'Invalid search engine' }, status: :unprocessable_entity
          end
        else
          render json: { error: 'Query or search_engine parameter is missing' }, status: :unprocessable_entity
        end
      end

      def handle_get_request
        raw_results = fetch_results(params[:job_id])
        search_result = SearchResult.find_by(job_id: params[:job_id])

        if search_result
          search_engine = search_result.search_engine

          formatted_results = case search_engine
                              when 'google'
                                format_google_results(raw_results)
                              when 'bing'
                                format_bing_results(raw_results)
                              when 'brave'
                                format_brave_results(raw_results)
                              else
                                []
                              end

          render json: { results: formatted_results }, status: :ok
        else
          render json: { error: 'No search results found for the given job ID' }, status: :not_found
        end
      end

      def initiate_search_job(search_engine, query, count, safesearch)
        job = case search_engine
              when 'google'
                GoogleSearchJob.perform_later(query: query, num: count.presence || 10, safesearch: safesearch.presence || 'off')
              when 'bing'
                BingSearchJob.perform_later(query: query, count: count.presence || 10, safesearch: safesearch)
              when 'brave'
                BraveSearchJob.perform_later(query: query, count: count.presence || 20, safesearch: safesearch.presence || 'moderate')
              else
                nil
              end
        job.job_id if job
      end

      def fetch_results(job_id)
        SearchResult.where(job_id: job_id).pluck(:results).map { |result| JSON.parse(result) }
      end

      def format_google_results(results)
        results.map do |parsed_result|
          {
            search_terms: parsed_result.dig('queries', 'request', 0, 'searchTerms'),
            total_results: parsed_result.dig('searchInformation', 'formattedTotalResults'),
            search_time: parsed_result.dig('searchInformation', 'formattedSearchTime'),
            items: format_google_items(parsed_result['items'] || [])
          }
        end
      end

      def format_google_items(items)
        items.map do |item|
          {
            title: item['title'],
            link: item['link'],
            snippet: item['snippet'],
            display_link: item['displayLink'],
            formatted_url: item['formattedUrl']
          }
        end
      end

      def format_bing_results(results)
        results.map do |parsed_result|
          {
            search_terms: parsed_result.dig('queryContext', 'originalQuery'),
            total_results: parsed_result.dig('webPages', 'totalEstimatedMatches'),
            search_url: parsed_result.dig('webPages', 'webSearchUrl'),
            items: format_bing_items(parsed_result.dig('webPages', 'value') || [])
          }
        end
      end

      def format_bing_items(items)
        items.map do |item|
          {
            title: item['name'],
            link: item['url'],
            snippet: item['snippet'],
            display_link: item['displayUrl'],
            date_published: item['datePublishedDisplayText'],
            cached_page_url: item['cachedPageUrl']
          }
        end
      end

      def format_brave_results(results)
        results.map do |parsed_result|
          if parsed_result['type'] == 'ErrorResponse'
            {
              search_terms: parsed_result.dig('query', 'original') || 'Unknown',
              total_results: nil,
              search_time: nil,
              items: [],
              error: parsed_result.dig('error', 'detail')
            }
          else
            {
              search_terms: parsed_result.dig('query', 'original'),
              total_results: nil,
              search_time: nil,
              items: format_brave_items(parsed_result)
            }
          end
        end
      end

      def format_brave_items(parsed_result)
        web_items = parsed_result.dig('web', 'results') || []
        video_items = parsed_result.dig('videos', 'results') || []

        formatted_web_items = web_items.map do |item|
          {
            title: item['title'] || 'No title available',
            link: item['url'] || '',
            snippet: item['description'] || 'No description available',
            display_link: item.dig('meta_url', 'hostname') || '',
            formatted_url: item.dig('meta_url', 'path') || ''
          }
        end

        formatted_video_items = video_items.map do |item|
          {
            title: item['title'] || 'No title available',
            link: item['url'] || '',
            snippet: item['description'] || 'No description available',
            display_link: item.dig('meta_url', 'hostname') || '',
            formatted_url: item.dig('meta_url', 'path') || '',
            thumbnail: item.dig('thumbnail', 'src') || ''
          }
        end

        formatted_web_items + formatted_video_items
      end
    end
  end
end
