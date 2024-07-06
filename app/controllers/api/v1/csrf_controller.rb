class Api::V1::CsrfController < ApplicationController
  def index
    token = form_authenticity_token
    Rails.logger.info "Generated CSRF token: #{token}"
    render json: { csrf_token: token }, status: :ok
  end
end
