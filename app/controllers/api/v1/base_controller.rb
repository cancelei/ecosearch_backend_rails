module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_user!
      protect_from_forgery with: :exception
      skip_before_action :verify_authenticity_token, if: :json_request?
      # comment 2 above lines when developing / testing.

      def json_request?
        request.format.json?
      end
    end
  end
end
