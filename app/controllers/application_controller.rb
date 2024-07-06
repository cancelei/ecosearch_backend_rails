class ApplicationController < ActionController::API
  include ActionController::RequestForgeryProtection
  forgery_protection_origin_check with: :null_session

  before_action :set_csrf_cookie

  private

  def set_csrf_cookie
    cookies['CSRF-TOKEN'] = form_authenticity_token
  end
end
