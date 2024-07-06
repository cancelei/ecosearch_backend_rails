class ApplicationController < ActionController::API
  include ActionController::RequestForgeryProtection
  include ActionController::Cookies

  protect_from_forgery with: :null_session

  before_action :set_csrf_cookie

  private

  def set_csrf_cookie
    cookies["CSRF-TOKEN"] = {
      value: form_authenticity_token,
      secure: Rails.env.production?
    }
  end
end
