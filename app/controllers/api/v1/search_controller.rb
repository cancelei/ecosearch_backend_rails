# app/controllers/api/v1/search_controller.rb

# Documentation:
# SearchController is responsible for handling search requests.
# It can handle both GET and POST requests.
# GET request will return the search results.
# POST request will initiate the search job.
# The search job will be performed by the respective search engine service.
# The search results will be stored in the database.
# GET request will fetch the search results from the database and format them.
# The formatted results will be returned as JSON response.
# The search engine services are GoogleSearchService, BingSearchService, and BraveSearchService.
# The search engine services will perform the search and return the results.
# The search engine services will be called by the respective job classes.
# The job classes are GoogleSearchJob, BingSearchJob, and BraveSearchJob.
# The job classes will be called by the SearchController.
# The search results will be stored in the SearchResult model.
# The SearchResult model will store the search results in JSON format.
# The search results will be formatted by the SearchController.
# The formatted results will be returned as JSON response.
# The search results will be displayed in the frontend.
# The frontend will display the search results in a user-friendly manner.
# The frontend will be developed using React.js.
module Api
  module V1
    class SearchController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [:search]
      before_action :authenticate_user!, except: [:search]

      def search
        if request.get?
          handle_get_request #2)this will return the search results.
        else
          handle_post_request #1)this will initiate the search job.
        end
      end

      private

      def handle_post_request
        if params[:query].present? && params[:search_engine].present?
          job_id = initiate_search_job(params[:search_engine], params[:query], params[:count], params[:safesearch]) #this will initiate the search job.
          if job_id
            render json: { job_id: job_id }, status: :accepted #this will show the job_id for the GET request.
          else
            render json: { error: 'Invalid search engine' }, status: :unprocessable_entity
          end
        else
          render json: { error: 'Query and/or search_engine parameter is missing' }, status: :unprocessable_entity
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
              #one of these will be performed, according to the search engine from the POST request.
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

      # fetch_results is part of GET request.
      def fetch_results(job_id)
        SearchResult.where(job_id: job_id).pluck(:results).map { |result| JSON.parse(result) }
      end

      # format_****_results & _items are part of GET request, they just format the results.
      # Ex: format_google_results will format the results from Google.
      # Ex: format_google_items will format the items from Google.
      #

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
